# Test GSS-NTLMSSP in Alpine

## Disclaimer

This was used for testing the following bug: https://github.com/gssapi/gss-ntlmssp/issues/97  
The issue was fixed in [gss-ntlmssp v1.3.0](https://github.com/gssapi/gss-ntlmssp/releases/tag/v1.3.0), so this repo is now outdated.

## Running the container

```bash
# Test the original library 
docker run --rm -it ghcr.io/laszlojau/gssntlmssp-alpine-debug:1.2.0

# Test the library with openssl3-specific changes removed
docker run --rm -it ghcr.io/laszlojau/gssntlmssp-alpine-debug:1.2.0-patched

# Run PowerShell interactively
docker run --rm --entrypoint /bin/sh -it ghcr.io/laszlojau/gssntlmssp-alpine-debug:1.2.0
/src # pwsh
PS /src> ./ntlm-test.ps1
```

## Building the container

If you wish to build your own container, you can run:

```
# Standard version
docker build . -t <your-repo>/gssntlmssp-alpine-debug:1.2.0 --build-arg ENABLE_OPENSSL_LEGACY=false

# openssl3-specific changes removed, legacy provider enabled via openssl config
docker build . -t <your-repo>/gssntlmssp-alpine-debug:1.2.0-patched --build-arg GSS_PATCH_OPENSSL3=true
```
