require 'formula'

class Glib < Formula
  homepage "http://developer.gnome.org/glib/"
  url "http://ftp.gnome.org/pub/gnome/sources/glib/2.42/glib-2.42.1.tar.xz"
  sha256 "8f3f0865280e45b8ce840e176ef83bcfd511148918cc8d39df2ee89b67dcf89a"
  revision 1

  bottle do
    root_url 'https://juliabottles.s3.amazonaws.com'
    cellar :any
    sha1 "69bcdbccfdec59abd1b434fe062873cc6d780897" => :mountain_lion
    sha1 "39dee4d2668a8f98aed6867eb4c7888dbdd7ce28" => :mavericks
    sha1 "24bfe415c99cf62c8c99c93efcdd320dc3f2474d" => :yosemite
  end

  option :universal
  option 'test', 'Build a debug build and run tests. NOTE: Not all tests succeed yet'
  option 'with-static', 'Build glib with a static archive.'

  depends_on 'staticfloat/juliadeps/pkg-config' => :build
  depends_on 'staticfloat/juliadeps/gettext'
  depends_on 'libffi'

  fails_with :llvm do
    build 2334
    cause "Undefined symbol errors while linking"
  end

  resource 'config.h.ed' do
    url 'https://trac.macports.org/export/111532/trunk/dports/devel/glib2/files/config.h.ed'
    version '111532'
    sha1 '0926f19d62769dfd3ff91a80ade5eff2c668ec54'
  end

  # https://bugzilla.gnome.org/show_bug.cgi?id=673135 Resolved as wontfix,
  # but needed to fix an assumption about the location of the d-bus machine
  # id file.
  patch do
    url "https://gist.githubusercontent.com/jacknagel/af332f42fae80c570a77/raw/7b5fd0d2e6554e9b770729fddacaa2d648327644/glib-hardcoded-paths.diff"
    sha1 "78bbc0c7349d7bfd6ab1bfeabfff27a5dfb1825a"
  end

  # Fixes compilation with FSF GCC. Doesn't fix it on every platform, due
  # to unrelated issues in GCC, but improves the situation.
  # Patch submitted upstream: https://bugzilla.gnome.org/show_bug.cgi?id=672777
  patch do
    url "https://gist.githubusercontent.com/jacknagel/9835034/raw/371fd57f7d3823c67dbd5bc738df7ef5ffc7545f/gio.patch"
    sha1 "b947912a4f59630c13e53056c8b18bde824860f4"
  end

  patch do
    url "https://gist.githubusercontent.com/jacknagel/9726139/raw/bc60b41fa23ae72f56128e16c9aa5d2d26c75c11/universal.patch"
    sha1 "ab9b8ba9d7c3fd493a0e24638a95e26f3fe613ac"
  end if build.universal?

  def install
    ENV.universal_binary if build.universal?

    inreplace %w[gio/gdbusprivate.c gio/xdgmime/xdgmime.c glib/gutils.c],
      "@@HOMEBREW_PREFIX@@", HOMEBREW_PREFIX

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    args = %W[
      --disable-maintainer-mode
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-dtrace
      --disable-libelf
      --prefix=#{prefix}
      --localstatedir=#{var}
      --with-gio-module-dir=#{HOMEBREW_PREFIX}/lib/gio/modules
    ]

    args << '--enable-static' if build.with? 'static'

    system "./configure", *args

    if build.universal?
      buildpath.install resource('config.h.ed')
      system "ed -s - config.h <config.h.ed"
    end

    system "make"
    # the spawn-multithreaded tests require more open files
    system "ulimit -n 1024; make check" if build.include? 'test'
    system "make install"

    # `pkg-config --libs glib-2.0` includes -lintl, and gettext itself does not
    # have a pkgconfig file, so we add gettext lib and include paths here.
    gettext = Formula["gettext"].opt_prefix
    inreplace lib+'pkgconfig/glib-2.0.pc' do |s|
      s.gsub! 'Libs: -L${libdir} -lglib-2.0 -lintl',
              "Libs: -L${libdir} -lglib-2.0 -L#{gettext}/lib -lintl"
      s.gsub! 'Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include',
              "Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include -I#{gettext}/include"
    end

    (share+'gtk-doc').rmtree
  end

  test do
    (testpath/'test.c').write <<-EOS.undent
      #include <string.h>
      #include <glib.h>

      int main(void)
      {
          gchar *result_1, *result_2;
          char *str = "string";

          result_1 = g_convert(str, strlen(str), "ASCII", "UTF-8", NULL, NULL, NULL);
          result_2 = g_convert(result_1, strlen(result_1), "UTF-8", "ASCII", NULL, NULL, NULL);

          return (strcmp(str, result_2) == 0) ? 0 : 1;
      }
      EOS
    flags = ["-I#{include}/glib-2.0", "-I#{lib}/glib-2.0/include", "-lglib-2.0"]
    system ENV.cc, "-o", "test", "test.c", *(flags + ENV.cflags.to_s.split)
    system "./test"
  end
end
