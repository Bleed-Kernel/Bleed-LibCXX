set -e
cd "$1/libcxx"

sed -i.orig 's/^#  if defined(__BIONIC__) || defined(__NuttX__) || defined(__Fuchsia__) || defined(__wasi__) ||  /#  if defined(__bleed__) || defined(__BIONIC__) || defined(__NuttX__) || defined(__Fuchsia__) || defined(__wasi__) ||/' include/__config
sed -i.orig 's/^#  elif defined(__Fuchsia__)$/#  elif defined(__Fuchsia__) || defined(__bleed__)/' include/__locale_dir/locale_base_api.h
sed -i.orig 's/^#elif defined(__Fuchsia__)$/#elif defined(__Fuchsia__) || defined(__bleed__)/' src/include/config_elast.h
rm -f include/__config.orig include/__locale_dir/locale_base_api.h.orig src/include/config_elast.h.orig

grep -q '__bleed__' include/__config
grep -q '__bleed__' include/__locale_dir/locale_base_api.h
grep -q '__bleed__' src/include/config_elast.h
