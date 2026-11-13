//! Read-only heuristic audit. No Dart AST: every finding requires verification.
use std::{collections::BTreeMap, env, fs, path::{Path, PathBuf}, process};

#[derive(Clone, Debug)]
struct Finding { rule: &'static str, priority: &'static str, path: String, line: usize, title: String, evidence: String, check: &'static str }

fn json_escape(s: &str) -> String {
    let mut result = String::from("\"");
    for ch in s.chars() {
        match ch {
            '"' => result.push_str("\\\""), '\\' => result.push_str("\\\\"),
            '\n' => result.push_str("\\n"), '\r' => result.push_str("\\r"),
            '\t' => result.push_str("\\t"), c if c.is_control() => result.push_str(&format!("\\u{:04x}", c as u32)),
            c => result.push(c),
        }
    }
    result.push('"'); result
}
fn lineno(s: &str, byte: usize) -> usize { s[..byte.min(s.len())].bytes().filter(|c| *c == b'\n').count() + 1 }
fn line_at(s: &str, byte: usize) -> String { s[..byte].rsplit('\n').next().unwrap_or("").to_string() + s[byte..].split('\n').next().unwrap_or("") }
fn has_any(s: &str, needles: &[&str]) -> bool { needles.iter().any(|n| s.contains(n)) }
fn walk(dir: &Path, files: &mut Vec<PathBuf>) -> std::io::Result<()> {
    const EXCLUDED: &[&str] = &[".git", ".dart_tool", ".idea", "build", "coverage", "node_modules", "ios", "android", "macos", "windows", "linux", "web", "generated", "gen", ".fvm", "Pods"];
    if dir.is_file() {
        if dir.extension().is_some_and(|ext| ext == "dart") && !is_generated(dir) { files.push(dir.to_path_buf()); }
        return Ok(());
    }
    if !dir.exists() { return Ok(()); }
    for entry in fs::read_dir(dir)? {
        let entry = entry?; let ty = entry.file_type()?;
        if ty.is_symlink() { continue; } // no symlink traversal; avoids escapes and loops
        let path = entry.path();
        if ty.is_dir() {
            if !EXCLUDED.contains(&entry.file_name().to_string_lossy().as_ref()) { walk(&path, files)?; }
        } else if ty.is_file() && path.extension().is_some_and(|ext| ext == "dart") && !is_generated(&path) { files.push(path); }
    }
    Ok(())
}
fn is_generated(path: &Path) -> bool {
    let s = path.file_name().unwrap_or_default().to_string_lossy();
    [".g.dart", ".freezed.dart", ".gr.dart", ".chopper.dart", ".mocks.dart", ".gen.dart", ".reflectable.dart"].iter().any(|end| s.ends_with(end)) || s.starts_with("flutter_gen")
}
fn add(out: &mut Vec<Finding>, file: &str, src: &str, at: usize, rule: &'static str, priority: &'static str, title: impl Into<String>, check: &'static str) {
    out.push(Finding { rule, priority, path: file.to_owned(), line: lineno(src,at), title: title.into(), evidence: line_at(src,at).trim().chars().take(140).collect(), check });
}
fn occurrences(s: &str, needle: &str) -> Vec<usize> { s.match_indices(needle).map(|(i,_)| i).collect() }
fn braces_empty(s: &str, start: usize) -> bool {
    let rest = &s[start..];
    let Some(open) = rest.find('{') else { return false; };
    if open > 100 { return false; }
    rest[open + 1..].find('}').is_some_and(|close| close < 100 && rest[open+1..open+1+close].trim().is_empty())
}
fn audit_file(file: &str, src: &str, max_lines: usize, findings: &mut Vec<Finding>, nav: &mut BTreeMap<&'static str,(String,usize)>) {
    let total = src.lines().count();
    if total > max_lines { add(findings,file,src,0,"large-dart-file","P3",format!("Archivo de {total} líneas: revisar responsabilidades, no dividir por tamaño únicamente"),"Examinar cohesión antes de extraer widgets o servicios."); }
    for at in occurrences(src,"catch (").into_iter().chain(occurrences(src,"catch(").into_iter()) {
        if let Some(end) = src[at..].find(')') {
            if end < 100 && braces_empty(src,at+end+1) { add(findings,file,src,at,"empty-catch","P1","Catch aparentemente vacío","Verificar intención y tratamiento de errores; puede haber comentarios."); }
        }
    }
    for at in occurrences(src,"setState(") {
        if src[at..].chars().take(65).collect::<String>().contains("async") { add(findings,file,src,at,"async-setstate-callback","P1","Posible callback async dentro de setState","Mover await fuera de setState y revisar mounted."); }
    }
    for at in occurrences(src,"initState(") {
        let head = &src[at..src.len().min(at+80)];
        if head.split('{').next().unwrap_or("").contains("async") { add(findings,file,src,at,"async-initstate","P1","initState aparentemente async","Mantener initState síncrono y delegar la operación."); }
    }
    for at in occurrences(src,"FutureBuilder") {
        let snip = &src[at..src.len().min(at+260)];
        if snip.contains("future:") && snip.split("future:").nth(1).is_some_and(|tail| tail.split(',').next().unwrap_or("").contains('(')) {
            add(findings,file,src,at,"future-created-in-futurebuilder","P2","Posible Future creado en FutureBuilder","Confirmar que el Future no se vuelve a crear en build.");
        }
    }
    for name in ["TextEditingController", "ScrollController", "PageController", "FocusNode", "AnimationController", "TabController"] {
        for at in occurrences(src,&format!("{name}(")) {
            let before = &src[..at]; let identifier = before.rsplit(|c: char| !(c.is_ascii_alphanumeric() || c == '_')).find(|token| !token.is_empty());
            // This only identifies candidate ownership; false positives are expected.
            if let Some(var) = identifier {
                if var != "=" && !src.contains(&format!("{var}.dispose(")) && !src.contains(&format!("{var} .dispose(")) {
                    add(findings,file,src,at,"possibly-undisposed-controller","P2",format!("Posible {name} sin dispose local"),"Confirmar propietario y si dispose ocurre en otro archivo/componente.");
                }
            }
        }
    }
    if let Some(at) = src.find("Timer.periodic(") {
        if !src.contains(".cancel(") { add(findings,file,src,at,"periodic-timer","P2","Timer periódico sin cancelación visible","Comprobar ownership y cancelación."); }
    }
    if let Some(at) = src.find("StreamSubscription<") {
        if !src.contains(".cancel(") { add(findings,file,src,at,"stream-subscription","P2","StreamSubscription sin cancelación visible","Comprobar owner y cancelación."); }
    }
    for at in occurrences(src,"ignore_for_file:") { add(findings,file,src,at,"filewide-lint-suppression","P3","Supresión de lints para el archivo","Justificar las excepciones y reducir alcance si corresponde."); }
    if let Some(at) = src.find("print(") { add(findings,file,src,at,"print-call","P3","Llamada print() a revisar","Comprobar privacidad y logging consistente."); }
    for (i,line) in src.lines().enumerate() {
        if !line.contains("await ") { continue; }
        let following = src.lines().skip(i+1).take(12).collect::<Vec<_>>().join("\n");
        if has_any(&following, &["setState(", "Navigator.", "ScaffoldMessenger.", "context.go(", "context.push(", "context.pop("]) && !has_any(&following, &["mounted", "context.mounted"]) {
            let at = src.lines().take(i).map(|l| l.len()+1).sum::<usize>().min(src.len());
            add(findings,file,src,at,"async-gap-review","P2","Await seguido de uso de UI/context sin mounted visible","Inspeccionar control de flujo y contexto real; señal heurística.");
            break;
        }
    }
    let maps = occurrences(src,"Map<String, dynamic>").len() + occurrences(src,"Map<String,dynamic>").len();
    if maps >= 5 { let at = src.find("Map<").unwrap_or(0); add(findings,file,src,at,"dynamic-map-density","P3",format!("{maps} Map<String,dynamic>"),"Considerar modelos tipados en fronteras API cuando aporte seguridad."); }
    for (kind,needles) in [("getx", &["Get.to(","Get.back(","Get.off(","Get.offAll("][..]), ("navigator", &["Navigator.push", "Navigator.pop", "Navigator.of("][..]), ("go_router", &["context.go(","context.push("][..])] {
        if let Some(at) = needles.iter().filter_map(|n| src.find(n)).min() { nav.entry(kind).or_insert((file.to_string(),lineno(src,at))); }
    }
}
fn report_json(root: &Path, scope: &str, scanned: usize, lines: usize, findings: &[Finding], skipped: &[String]) -> String {
    let mut counts = BTreeMap::new(); for f in findings { *counts.entry(f.priority).or_insert(0usize) += 1; }
    let count_json = counts.iter().map(|(k,v)| format!("{}:{v}",json_escape(k))).collect::<Vec<_>>().join(",");
    let fs_json = findings.iter().map(|f| format!("{{\"rule\":{},\"priority\":{},\"confidence\":\"heuristic\",\"path\":{},\"line\":{},\"title\":{},\"evidence\":{},\"check\":{}}}",json_escape(f.rule),json_escape(f.priority),json_escape(&f.path),f.line,json_escape(&f.title),json_escape(&f.evidence),json_escape(f.check))).collect::<Vec<_>>().join(",");
    let skipped_json = skipped.iter().map(|s| json_escape(s)).collect::<Vec<_>>().join(",");
    format!("{{\"root\":{},\"scope\":{},\"scanned_files\":{},\"scanned_lines\":{},\"counts_by_priority\":{{{}}},\"findings\":[{}],\"skipped\":[{}],\"caveats\":[\"Heuristic signals only; no Dart AST or runtime analysis.\",\"Findings are not confirmed bugs. Verify with code inspection and tests.\",\"No source files modified.\"]}}",json_escape(&root.display().to_string()),json_escape(scope),scanned,lines,count_json,fs_json,skipped_json)
}
fn usage() -> ! { eprintln!("Usage: flutter-rails-audit [--root DIR] [--path lib] [--format text|json] [--output FILE] [--large-file-lines N]"); process::exit(2) }
fn run() -> Result<(),String> {
    let mut root=PathBuf::from("."); let mut scope=String::from("lib"); let mut fmt=String::from("text"); let mut output=None; let mut large=700usize;
    let mut args=env::args().skip(1);
    while let Some(k)=args.next() { let v=if k == "--help" || k == "-h" {usage()} else {args.next().unwrap_or_else(||usage())}; match k.as_str() {"--root"=>root=PathBuf::from(v),"--path"=>scope=v,"--format"=>fmt=v,"--output"=>output=Some(PathBuf::from(v)),"--large-file-lines"=>large=v.parse().map_err(|_|"Invalid --large-file-lines")?,_=>usage()} }
    if fmt!="text" && fmt!="json" { return Err("--format must be text|json".into()); }
    root=fs::canonicalize(root).map_err(|e|format!("Invalid root: {e}"))?;
    if !root.is_dir() { return Err("Root must be a directory".into()); }
    let scope_path=root.join(&scope);
    // Canonicalize parent path when present: reject traversal and symlinks escaping root.
    let checked=if scope_path.exists() { fs::canonicalize(&scope_path).map_err(|e|e.to_string())? } else { return Err(format!("Path does not exist: {}",scope_path.display())); };
    if !checked.starts_with(&root) { return Err("--path escapes --root".into()); }
    let mut files=Vec::new(); walk(&checked,&mut files).map_err(|e|e.to_string())?; files.sort();
    let mut findings=Vec::new(); let mut nav=BTreeMap::new(); let mut skipped=Vec::new(); let mut scanned=0; let mut lines=0;
    for file in files { let path=file.strip_prefix(&root).unwrap_or(&file).to_string_lossy().replace('\\',"/");
        match fs::metadata(&file) { Ok(meta) if meta.len()>2_000_000 => {skipped.push(format!("{path}: >2 MB")); continue;},Err(e)=>{skipped.push(format!("{path}: {e}"));continue;},_=>{} }
        match fs::read_to_string(&file) { Ok(source)=> {scanned+=1; lines+=source.lines().count(); audit_file(&path,&source,large,&mut findings,&mut nav); },Err(e)=> skipped.push(format!("{path}: {e}")) }
    }
    if nav.len()>1 { let names=nav.keys().copied().collect::<Vec<_>>().join(", "); for (kind,(path,line)) in nav {findings.push(Finding {rule:"mixed-navigation-styles",priority:"P2",path:path.clone(),line,title:format!("Múltiples APIs de navegación: {names}"),evidence:format!("{kind} en {path}:{line}"),check:"Confirmar coexistencia intencional y pruebas de rutas/deeplinks."});} }
    findings.sort_by(|a,b| a.priority.cmp(b.priority).then(a.path.cmp(&b.path)).then(a.line.cmp(&b.line)).then(a.rule.cmp(b.rule)));
    let text = if fmt == "json" { report_json(&root,&scope,scanned,lines,&findings,&skipped) } else {
        let mut s=format!("Flutter Engineering Audit (HEURISTIC)\nRoot: {} | scope: {}\nFiles: {} | lines: {} | signals: {}\n",root.display(),scope,scanned,lines,findings.len());
        for f in &findings {s.push_str(&format!("\n[{}] {} | {}:{}\n  {}\n  evidence: {}\n  verify: {}\n",f.priority,f.rule,f.path,f.line,f.title,f.evidence,f.check));}
        if !skipped.is_empty() {s.push_str(&format!("\nSkipped: {}\n",skipped.join("; ")));}
        s.push_str("\nCAVEAT: heuristic leads, NOT confirmed bugs. No source files modified.\n"); s
    };
    if let Some(dest)=output { if let Some(parent)=dest.parent(){fs::create_dir_all(parent).map_err(|e|e.to_string())?;} fs::write(&dest,format!("{text}\n")).map_err(|e|e.to_string())?; println!("Report written to {}",dest.display()); } else {print!("{text}");}
    Ok(())
}
fn main() { if let Err(e)=run(){eprintln!("Error: {e}");process::exit(2)} }

#[cfg(test)] mod tests { use super::*;
    #[test] fn catches_empty_catch(){let mut out=Vec::new();let mut nav=BTreeMap::new();audit_file("lib/a.dart","void f() { try {} catch (e) {} }",700,&mut out,&mut nav);assert!(out.iter().any(|f|f.rule=="empty-catch"));}
    #[test] fn ignores_nonempty_catch(){let mut out=Vec::new();let mut nav=BTreeMap::new();audit_file("lib/a.dart","void f() { try {} catch (e) { log(e); } }",700,&mut out,&mut nav);assert!(!out.iter().any(|f|f.rule=="empty-catch"));}
    #[test] fn json_escapes(){assert_eq!(json_escape("a\"b\n"),"\"a\\\"b\\n\"");}
    #[test] fn generated_skipped(){assert!(is_generated(Path::new("model.freezed.dart")));}
}
