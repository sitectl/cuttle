# Building the oauth2-proxy package #

## Fetching oauth2_proxy ##

1. Install Go and set up a Go environment

   http://golang.org/doc/install

2. Get the oauth2_proxy source and build the binary in your $GOPATH

    ```
    go get github.com/bitly/oauth2_proxy
    ```

## Building the Debian package ##

1. Install 'fpm'

   https://github.com/jordansissel/fpm/blob/master/README.md

2. Build the oauth2-proxy package

    ```
    cd $GOPATH/bin
    fpm -s dir -t deb -n oauth2_proxy -v $VERSION+$NUM~$COMMIT --prefix /opt/oauth2_proxy/bin oauth2_proxy
    ```

   At the time of writing, the latest released version of oauth2_proxy is
   2.0.1.  To make sure we can upgrade this package between releases with our
   own builds and that the next released version properly supercedes our last
   package build, we set $VERSION to the latest released version and each time
   we build the package we increment $NUM and set $COMMIT to the short hash of
   the oauth2_proxy repo our packaged binary was built from.  For example:

    ```
    fpm -s dir -t deb -n oauth2_proxy -v 2.0.1+1~a631197 --prefix /opt/oauth2_proxy/bin oauth2_proxy
    ```

## Mirroring the Debian package ##

1. Upload package to the `blueboxcloud / misc` repo at https://packagecloud.io

   https://boxpanel.bluebox.net/private/service_passwords

   If you do not have access to this location, please ask in \#bluebox-ci or
   \#sitecontroller on Slack and someone should be able to upload the package
   for you.

2. Mirror package to the BBC apt mirror

   Once the package has been uploaded to the `blueboxcloud / misc` package
   cloud repo, ask in \#sitecontroller on Slack for a mirror sync.  Once the
   package is synced to the BBC apt mirror, re-run the oauth2_proxy playbook.
