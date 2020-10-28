#!/bin/zsh

tempdir=$(mktemp -d)
tempfile=$tempdir/archive.xcarchive

xcodebuild -quiet -project ./iCryptr.xcodeproj -config Release -scheme iCryptr -archivePath $tempfile archive
mv "$tempfile/Products/Applications" "$tempfile/Payload"


pushd "$tempfile/"
zip -q -r ./app.ipa ./Payload
popd

rm ./iCryptr.ipa
mv "$tempfile/app.ipa" ./iCryptr.ipa
