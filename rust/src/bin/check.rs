//! Runs existing Dart/Flutter quality checks without applying fixes or upgrades.
use std::{env, fs, path::{Path,PathBuf}, process::{self,Command,Stdio},thread,time::{Duration,Instant}};

fn locate(name:&str)->Option<PathBuf> {
    env::var_os("PATH")?.to_string_lossy().split(if cfg!(windows){';'}else{':'}).map(|p|PathBuf::from(p).join(if cfg!(windows){format!("{name}.bat")}else{name.to_string()})).find(|p|p.is_file())
}
fn run_check(name:&str, executable:&Path, args:&[&str], root:&Path, timeout:u64)->bool {
    println!("\n$ {} {}",executable.display(),args.join(" "));
    let mut cmd=Command::new(executable);cmd.args(args).current_dir(root).stdout(Stdio::piped()).stderr(Stdio::piped());
    let Ok(mut child)=cmd.spawn() else {eprintln!("[{name}] could not spawn command");return false;};
    let start=Instant::now();let mut expired=false;
    loop {
        match child.try_wait(){Ok(Some(_))=>break,Ok(None)=>{if start.elapsed()>Duration::from_secs(timeout){expired=true;let _=child.kill();break;}thread::sleep(Duration::from_millis(100));},Err(e)=>{eprintln!("[{name}] poll error: {e}");let _=child.kill();break;}}
    }
    match child.wait_with_output(){Ok(output)=>{
        let combined=format!("{}{}",String::from_utf8_lossy(&output.stdout),String::from_utf8_lossy(&output.stderr));
        let lines=combined.lines().collect::<Vec<_>>();if lines.len()>130 {println!("... {} earlier lines omitted",lines.len()-130);}for line in lines.iter().skip(lines.len().saturating_sub(130)){println!("{line}");}
        let ok=output.status.success()&&!expired;println!("[{}] {name} (exit {:?})",if ok{"PASS"}else if expired{"TIMEOUT"}else{"FAIL"},output.status.code());ok
    },Err(e)=>{eprintln!("[{name}] output error: {e}");false}}
}
fn help()->!{eprintln!("Usage: flutter-rails-check [--root DIR] [--mode quick|full] [--test test/x_test.dart] [--timeout SECONDS]");process::exit(2)}
fn run()->Result<i32,String>{
    let(mut root,mut mode,mut test,mut timeout)=(PathBuf::from("."),String::from("quick"),None,240u64);
    let mut args=env::args().skip(1);
    while let Some(k)=args.next(){let v=if k=="--help"||k=="-h"{help()}else{args.next().unwrap_or_else(||help())};match k.as_str(){"--root"=>root=PathBuf::from(v),"--mode"=>mode=v,"--test"=>test=Some(v),"--timeout"=>timeout=v.parse().map_err(|_|"Invalid timeout")?,_=>help()}}
    if mode!="quick"&&mode!="full"{return Err("--mode must be quick|full".into());}if timeout==0{return Err("timeout must be >0".into());}
    root=fs::canonicalize(&root).map_err(|e|e.to_string())?;
    if !root.join("pubspec.yaml").is_file(){return Err("Root must contain pubspec.yaml".into());}
    let dart=locate("dart");let flutter=locate("flutter");
    if dart.is_none()&&flutter.is_none(){eprintln!("[UNAVAILABLE] Dart/Flutter SDK missing");return Ok(2);}
    let mut success=true;let mut ran=false;
    let scopes=["lib","test"].into_iter().filter(|s|root.join(s).is_dir()).collect::<Vec<_>>();
    if let Some(dart)=dart.as_ref(){if !scopes.is_empty(){ran=true;let mut cmd=vec!["format","--output=none","--set-exit-if-changed"];cmd.extend(scopes.iter().copied());success &= run_check("format",dart,&cmd,&root,timeout);}}
    else{eprintln!("[UNAVAILABLE] dart CLI missing: format check skipped");}
    if let Some(flutter)=flutter.as_ref(){ran=true;success &= run_check("analyze",flutter,&["analyze","--no-pub"],&root,timeout);}
    else if let Some(dart)=dart.as_ref(){ran=true;success &= run_check("analyze",dart,&["analyze"],&root,timeout);}
    if mode=="full" && root.join("test").is_dir() {
        if let Some(flutter)=flutter.as_ref(){ran=true;success &= run_check("tests",flutter,&["test","--no-pub"],&root,timeout);}else{eprintln!("[UNAVAILABLE] Flutter CLI missing: tests skipped");}
    }else if let Some(test)=test{
        let target=fs::canonicalize(root.join(&test)).map_err(|e|format!("Invalid --test: {e}"))?;
        if !target.starts_with(&root)||!target.extension().is_some_and(|e|e=="dart")||!target.is_file(){return Err("--test must be an existing .dart file inside root".into());}
        if let Some(flutter)=flutter.as_ref(){ran=true;let relative=target.strip_prefix(&root).map_err(|e|e.to_string())?.to_string_lossy().to_string();success &= run_check("tests",flutter,&["test","--no-pub",&relative],&root,timeout);}else{eprintln!("[UNAVAILABLE] Flutter CLI missing: targeted tests skipped");}
    }else if mode=="quick"{println!("[NOT RUN] Tests require --test in quick mode");}
    else {println!("[NOT RUN] No test directory");}
    if !ran {Ok(2)} else {Ok(if success{0}else{1})}
}
fn main(){match run(){Ok(code)=>process::exit(code),Err(e)=>{eprintln!("Error: {e}");process::exit(2)}}}
