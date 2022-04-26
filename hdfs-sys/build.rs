extern crate bindgen;

use anyhow::Result;
use std::env;
use std::path::PathBuf;

fn main() -> Result<()> {
    match env::var("HADOOP_HOME") {
        Ok(hadoop_home) => with_hadoop_home(&hadoop_home),
        Err(_) => without_hadoop_home(),
    }
}

fn with_hadoop_home(hadoop_home: &str) -> Result<()> {
    println!("cargo:rustc-link-search=native={hadoop_home}/lib/native");
    println!("cargo:rustc-link-lib=hdfs");

    let bindings = bindgen::Builder::default()
        .header(format!("{hadoop_home}/include/hdfs.h"))
        .generate_comments(false)
        .generate()
        .expect("bind generated");

    let out_path = PathBuf::from(env::var("OUT_DIR")?);
    bindings.write_to_file(out_path.join("bindings.rs"))?;

    Ok(())
}

fn without_hadoop_home() -> Result<()> {
    let mut builder = cc::Build::new();

    let hadoop_src =
        "./vendor/hadoop/hadoop-hdfs-project/hadoop-hdfs-native-client/src/main/native/libhdfs";

    // Tricks for libhdfs requires a config.h that generated by cmake.
    // We leave an empty one so that our build works.
    builder.include("./vendor/include");
    // Include headers.
    builder.include(hadoop_src);
    builder.include(format!("{hadoop_src}/os"));
    builder.include(format!("{hadoop_src}/include"));

    if cfg!(windows) {
        builder.include(format!("{hadoop_src}/os/windows"));
    } else {
        builder.include(format!("{hadoop_src}/os/posix"));
    }
    // Handle java headers.
    let java_home = env::var("JAVA_HOME")?;
    builder.include(format!("{java_home}/include"));
    if cfg!(unix) {
        builder.include(format!("{java_home}/include/linux"));
    }

    // Add files
    builder.file(format!("{hadoop_src}/exception.c"));
    builder.file(format!("{hadoop_src}/hdfs.c"));
    builder.file(format!("{hadoop_src}/jni_helper.c"));
    builder.file(format!("{hadoop_src}/jclasses.c"));

    // Ignore all warnings from libhdfs.
    builder.warnings(false);
    // Compile
    builder.compile("hdfs");

    println!("cargo:rustc-link-lib=hdfs");

    let bindings = bindgen::Builder::default()
        .header(format!("{hadoop_src}/include/hdfs/hdfs.h"))
        .generate_comments(false)
        .generate()
        .expect("bind generated");

    let out_path = PathBuf::from(env::var("OUT_DIR")?);
    bindings.write_to_file(out_path.join("bindings.rs"))?;

    Ok(())
}
