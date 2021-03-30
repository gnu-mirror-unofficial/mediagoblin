;;; GNU MediaGoblin -- federated, autonomous media hosting
;;; Copyright © 2015, 2016 David Thompson <davet@gnu.org>
;;; Copyright © 2016 Christopher Allan Webber <cwebber@dustycloud.org>
;;; Copyright © 2019, 2020, 2021 Ben Sturmfels <ben@sturm.com.au>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; ========================================
;;;
;;; This file is also part of GNU MediaGoblin, but we're leaving it under GPLv3
;;; for easy merge back and forth between Guix proper.
;;;
;;; ========================================
;;;
;;; WORK IN PROGRESS - UNRESOLVED ISSUES:
;;;
;;; 1. Switch MediaGoblin to using python-feedparser instead of
;;; werkzeug.contrib.atom so we can use Guix's newer version of werkzeug. DONE
;;;
;;; 2. Package python-soundfile.
;;;
;;; 3. Work out why libsndfile isn't being found (maybe packaging it rather than
;;; installing from PyPI would fix it?). See `bin/python -m pytest
;;; ./mediagoblin/tests/test_audio.py --boxed --pdb`.
;;;
;;; 4. Fix other test suite errors.
;;;
;;; 5. H264 videos won't transcode: "GStreamer: missing H.264 decoder".
;;;
;;; 6. Don't have NPM in this environment yet. Maybe we use it, or maybe we
;;; modify MediaGoblin to provide most functionality without it?
;;;
;;; 7. Haven't even looked at running celery.
;;;
;;; With `guix environment' you can use guix as kind of a universal
;;; virtualenv, except a universal virtualenv with magical time traveling
;;; properties and also, not just for Python.
;;;
;;; ========================================
;;;
;;; Assuming you have Guix installed, run:
;;;
;;;   guix environment -l guix-env.scm --container --network --expose=$HOME/.bash_history
;;;
;;; or (untested):
;;;
;;;   guix environment -l guix-env.scm --pure
;;;
;;; or (untested):
;;;
;;;   guix environment -l guix-env.scm
;;;
;;; While using --pure is a robust way to ensure that other environment
;;; variables don't cause unexpected behaviour, it may trip up aspects of your
;;; development tools, such as removing reference to $EDITOR. Feel free to
;;; remove the --pure.
;;;
;;; You'll need to run the above command every time you close your terminal or
;;; restart your system, so a handy way to save having to remember is to install
;;; "direnv" an then create a ".envrc" file in your current directory containing
;;; the following and then run "direnv allow" when prompted:
;;;
;;;   use guix -l guix-env.scm
;;;
;;; To set things up for the first time, you'll also need to run the following.
;;;
;;;   git submodule update --init
;;;   ./bootstrap.sh
;;;   ./configure --without-virtualenv
;;;   make
;;;
;;; The following are needed the first time only if you're using a regular or
;;; --pure environment, but are needed each time with a --container:
;;;
;;;   rm -rf bin include lib lib64 pyvenv.cfg
;;;   python3 -m venv --system-site-packages . && bin/python setup.py develop --no-deps
;;;   bin/python -m pip install soundfile
;;;   bin/python -m pip install --force-reinstall pytest pytest-xdist pytest-forked
;;;
;;; ... wait whaaat, what's that venv line?!  I thought you said this
;;; was a reasonable virtualenv replacement!  Well it is and it will
;;; be, but there's a catch, and the catch is that Guix doesn't know
;;; about this directory and "setup.py dist" is technically necessary
;;; for certain things to run, so we have a virtualenv with nothing
;;; in it but this project itself.
;;;
;;; The devtools/update_extlib.sh script won't run on Guix due to missing
;;; "/usr/bin/env", so then run:
;;;   node node_modules/.bin/bower install
;;;   ./devtools/update_extlib.sh
;;;
;;; Migrate the database and add a user:
;;;
;;;   bin/gmg --conf_file mediagoblin.ini dbupdate
;;;   bin/gmg --conf_file mediagoblin.ini adduser --username admin --password a --email admin@example.com
;;;
;;; Start the server. The ./lazyserver.sh script doesn't currently work:
;;;
;;;   PYTHONPATH=lib/python3.8/site-packages:$PYTHONPATH CELERY_ALWAYS_EAGER=true paster serve paste.ini --reload
;;;
;;; Run the tests:
;;;
;;;  PYTHONPATH="${PYTHONPATH}:$(pwd)" ./runtests.sh
;;;
;;; or:
;;;
;;;  bin/python -m pytest ./mediagoblin/tests --boxed
;;;
;;; Now notably this is goofier looking than running a virtualenv,
;;; but soon I'll do something truly evil (I hope) that will make
;;; the virtualenv and path-hacking stuff unnecessary.
;;;
;;; Have fun!

(use-modules (ice-9 match)
             (srfi srfi-1)
             (guix packages)
             (guix licenses)
             (guix download)
             (guix git-download)
             (guix build-system gnu)
             (guix build-system python)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages base)
             (gnu packages certs)
             (gnu packages check)
             (gnu packages databases)
             (gnu packages pdf)
             (gnu packages python)
             (gnu packages python-crypto)
             (gnu packages python-web)
             (gnu packages python-xyz)
             (gnu packages sphinx)
             (gnu packages gstreamer)
             (gnu packages glib)
             (gnu packages pulseaudio)
             (gnu packages rsync)
             (gnu packages ssh)
             (gnu packages time)
             (gnu packages video)
             (gnu packages version-control)
             (gnu packages xml)
             ((guix licenses) #:select (expat zlib) #:prefix license:))

;; =================================================================
;; These packages are on their way into Guix proper but haven't made
;; it in yet... or they're old versions of packages we're pinning
;; ourselves to...
;; =================================================================

;; Need soundfile for audio spectrograms.

;; =================================================================

(define mediagoblin
  (package
    (name "mediagoblin")
    (version "0.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "mediagoblin" version))
       (sha256
        (base32
         "0p2gj4z351166d1zqmmd8wc9bzb69w0fjm8qq1fs8dw2yhcg2wwv"))))
    (build-system python-build-system)
    (arguments
     ;; Complains about missing gunicorn. Not sure where that comes from.
     '(#:tests? #f))
    (native-inputs
     `(
       ;; ("python-pytest-6" ,python-pytest)
       ("nss-certs" ,nss-certs)))
    (propagated-inputs
     `(("python-alembic" ,python-alembic)
       ;; ("python-pytest-xdist" ,python-pytest-xdist)
       ;; ("python-pytest-forked" ,python-pytest-forked)
       ("python-celery" ,python-celery)
       ("python-kombu" ,python-kombu)
       ("python-webtest" ,python-webtest)
       ("python-pastedeploy" ,python-pastedeploy)
       ("python-paste" ,python-paste)
       ("python-pastescript" ,python-pastescript)
       ("python-translitcodec" ,python-translitcodec)
       ("python-babel" ,python-babel)
       ("python-configobj" ,python-configobj)
       ("python-dateutil" ,python-dateutil)
       ("python-itsdangerous" ,python-itsdangerous)
       ("python-jinja2" ,python-jinja2)
       ("python-jsonschema" ,python-jsonschema)
       ("python-lxml" ,python-lxml)
       ("python-markdown" ,python-markdown)
       ("python-oauthlib" ,python-oauthlib)
       ("python-pillow" ,python-pillow)
       ("python-py-bcrypt" ,python-py-bcrypt)
       ("python-pyld" ,python-pyld)
       ("python-pytz" ,python-pytz)
       ("python-requests" ,python-requests)
       ("python-setuptools" ,python-setuptools)
       ("python-sphinx" ,python-sphinx)
       ("python-docutils" ,python-docutils)
       ("python-sqlalchemy" ,python-sqlalchemy)
       ("python-unidecode" ,python-unidecode)
       ("python-werkzeug" ,python-werkzeug)
       ("python-exif-read" ,python-exif-read)
       ("python-wtforms" ,python-wtforms)
       ("python-email-validator" ,python-email-validator)
       ("python-feedgenerator" ,python-feedgenerator)))
    (home-page "http://mediagoblin.org/")
    (synopsis "Web application for media publishing")
    (description "MediaGoblin is a web application for publishing all kinds of
media.")
    (license agpl3+)))

(package
  (inherit mediagoblin)
  (name "mediagoblin-hackenv")
  (version "git")
  (inputs
   `(;;; audio/video stuff
     ("openh264" ,openh264)
     ("gstreamer" ,gstreamer)
     ("gst-libav" ,gst-plugins-base)
     ("gst-plugins-base" ,gst-plugins-base)
     ("gst-plugins-good" ,gst-plugins-good)
     ("gst-plugins-bad" ,gst-plugins-bad)
     ("gst-plugins-ugly" ,gst-plugins-ugly)
     ("gobject-introspection" ,gobject-introspection)
     ("libsndfile" ,libsndfile)
     ;;; PDF
     ("poppler" ,poppler)
     ;; useful to have!
     ("coreutils" ,coreutils)
     ;; used by runtests.sh!
     ("which" ,which)
     ("git" ,git)
     ("automake" ,automake)
     ("autoconf" ,autoconf)
     ,@(package-inputs mediagoblin)))
  (propagated-inputs
   `(("python" ,python)
     ("python-virtualenv" ,python-virtualenv)
     ("python-pygobject" ,python-pygobject)
     ("python-gst" ,python-gst)
     ;; Needs python-gst in order for all tests to pass
     ("python-numpy" ,python-numpy)  ; this pulls in texlive...
                                     ; and texlive-texmf is very large...
     ("python-chardet", python-chardet)
     ("python-psycopg2" ,python-psycopg2)
     ;; For developing
     ("openssh" ,openssh)
     ("git" ,git)
     ("rsync" ,rsync)
     ,@(package-propagated-inputs mediagoblin))))
