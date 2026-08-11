{
  description = "hdrs development environment";

  inputs.nixpkgs.url =
    "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      hadoopVersion = "3.3.6";
      hadoop = pkgs.stdenvNoCC.mkDerivation {
        pname = "hadoop";
        version = hadoopVersion;

        src = pkgs.fetchurl {
          urls = [
            "https://mirrors.nju.edu.cn/apache/hadoop/common/hadoop-${hadoopVersion}/hadoop-${hadoopVersion}.tar.gz"
            "https://mirrors.huaweicloud.com/apache/hadoop/common/hadoop-${hadoopVersion}/hadoop-${hadoopVersion}.tar.gz"
            "https://archive.apache.org/dist/hadoop/common/hadoop-${hadoopVersion}/hadoop-${hadoopVersion}.tar.gz"
          ];
          hash = "sha512-3j6souBRfktWmoi2PIn64Zy4rGwB/5kPH/jwzA8xKMjooj2wFXfKVioOC7G0o4ifjHQ4TmCc1V5Teq2j3Kqfig==";
        };

        dontStrip = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -R . "$out/"
          chmod -R u+w "$out/bin" "$out/sbin" "$out/libexec"
          patchShebangs "$out/bin" "$out/sbin" "$out/libexec"
          runHook postInstall
        '';
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        hardeningDisable = [
          "fortify"
          "fortify3"
        ];

        packages = with pkgs; [
          cargo
          clang
          clippy
          hadoop
          lld
          pkg-config
          rustc
          rustfmt
          temurin-bin-17
        ];

        shellHook = ''
          export CC=${pkgs.clang}/bin/clang
          export CXX=${pkgs.clang}/bin/clang++

          export JAVA_HOME=${pkgs.temurin-bin-17}
          export HADOOP_HOME=${hadoop}
          export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
          export PATH="$JAVA_HOME/bin:$HADOOP_HOME/bin:$PATH"
          export CLASSPATH="$HADOOP_CONF_DIR:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*"
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}:$HADOOP_HOME/lib/native:$JAVA_HOME/lib/server''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

          export HDRS_TEST="''${HDRS_TEST:-on}"
          export HDRS_NAMENODE="''${HDRS_NAMENODE:-default}"
          export HDRS_WORKDIR="''${HDRS_WORKDIR:-/tmp/hdrs/}"
          mkdir -p "$HDRS_WORKDIR"
        '';
      };
    };
}
