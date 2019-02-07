pkg_origin=socratest
pkg_version=0.0.1

do_build() {
  return 0
}

do_install() {
  mkdir -p "${pkg_prefix}/bin"
  local rf="${pkg_prefix}/bin/run_forever"
  echo '#!/bin/sh' > "$rf"
  echo 'while [ 1 = 1 ]; do' >> "$rf"
  echo '  echo "Hello..."' >> "$rf"
  echo '  sleep 1' >> "$rf"
  echo 'done' >> "$rf"
  chmod +x "$rf"
}
