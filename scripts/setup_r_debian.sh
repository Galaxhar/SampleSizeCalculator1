#!/bin/sh
# Instalacao local para este ambiente Debian 13 amd64. Sem alterar /usr ou /etc.
# APT verifica assinatura do indice e SHA256 do pacote. Nao desativa TLS.
set -eu
tool_root=${SAMPLE_SIZE_TOOLS:-/workspace/tooling}
r_version=4.5.0-3
test "$(dpkg --print-architecture)" = amd64
mkdir -p "$tool_root/apt/lists/partial" "$tool_root/apt/cache/archives/partial" \
  "$tool_root/apt/sourceparts" "$tool_root/apt/confparts" "$tool_root/r-debs" "$tool_root/bin"
cat > "$tool_root/apt/apt.conf" <<EOF
Dir::Etc::main "-";
Dir::Etc::parts "$tool_root/apt/confparts";
Dir::Etc::sourcelist "$tool_root/apt/sources.list";
Dir::Etc::sourceparts "$tool_root/apt/sourceparts";
Dir::State::lists "$tool_root/apt/lists";
Dir::Cache "$tool_root/apt/cache";
Dir::Cache::archives "$tool_root/apt/cache/archives";
APT::Get::List-Cleanup "0";
APT::Sandbox::User "$(id -un)";
Acquire::Languages "none";
EOF
cat > "$tool_root/apt/sources.list" <<'EOF'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie main
EOF
export APT_CONFIG="$tool_root/apt/apt.conf"
/usr/bin/apt-get update
cd "$tool_root/r-debs"
/usr/bin/apt-get download "r-base-core=$r_version"
expected_hash=$(/usr/bin/apt-cache show "r-base-core=$r_version" | awk '/^SHA256:/ {print $2; exit}')
test -n "$expected_hash"
printf '%s  %s\n' "$expected_hash" "r-base-core_${r_version}_amd64.deb" | sha256sum -c -
mkdir -p "$tool_root/r-local"
dpkg-deb -x "r-base-core_${r_version}_amd64.deb" "$tool_root/r-local"
python3 - "$tool_root" <<'PY'
from pathlib import Path
import sys
tool = Path(sys.argv[1]).resolve()
root = tool / 'r-local'
etc = root / 'usr/lib/R/etc'
for path in etc.iterdir():
    if path.is_symlink():
        name = path.name
        path.unlink()
        source = root / 'etc/R' / name
        if source.exists():
            path.write_bytes(source.read_bytes())
        elif name == 'Renviron':
            path.write_bytes((etc / 'Renviron.ucf').read_bytes())
binary = root / 'usr/lib/R/bin/R'
text = binary.read_text()
for name, relative in [('R_HOME_DIR','usr/lib/R'), ('R_SHARE_DIR','usr/share/R/share'),
                        ('R_INCLUDE_DIR','usr/share/R/include'), ('R_DOC_DIR','usr/share/doc/R')]:
    text = text.replace(f'{name}=/{relative}', f'{name}={root / relative}')
binary.write_text(text)
wrapper = tool / 'bin/Rscript'
wrapper.write_text(f'#!/bin/sh\nexport RHOME="{root / "usr/lib/R"}"\nexec "{root / "usr/bin/Rscript"}" "$@"\n')
wrapper.chmod(0o755)
PY
"$tool_root/bin/Rscript" --vanilla -e 'stopifnot(getRversion() == "4.5.0"); print(R.version.string); stopifnot(abs(stats::pnorm(0)-.5)<1e-12); grDevices::png(tempfile(fileext=".png")); graphics::plot(1:3); grDevices::dev.off()'
printf 'Rscript disponivel em %s/bin/Rscript\n' "$tool_root"
