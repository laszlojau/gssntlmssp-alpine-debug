ARG SDK_VERSION=6.0.418-alpine3.18

# Build the GSS-NTLMSSP library
FROM mcr.microsoft.com/dotnet/sdk:$SDK_VERSION AS gss_ntlm

RUN apk add --no-cache git make m4 autoconf automake gcc g++ krb5-dev openssl-dev gettext-dev
RUN apk add --no-cache libtool libxml2 libxslt libunistring-dev zlib-dev samba-dev
RUN apk add --no-cache patch

RUN git clone https://github.com/gssapi/gss-ntlmssp
WORKDIR gss-ntlmssp

ARG GSS_NTLMSSP_VERSION=1.2.0
ARG GSS_PATCH_OPENSSL3=false

RUN git checkout v${GSS_NTLMSSP_VERSION}

COPY ./openssl3-remove.patch ./openssl3-remove.patch

RUN if [ "${GSS_PATCH_OPENSSL3:-}" = "true" ]; then \
    patch -u ./src/crypto.c -i ./openssl3-remove.patch; \
  else \
    echo "GSS_PATCH_OPENSSL3 was set to false, not patching crypto.c"; \
  fi

ARG LDFLAGS=-lintl

RUN autoreconf -f -i
RUN ./configure --without-manpages --without-wbclient --disable-nls --disable-dependency-tracking
RUN make
RUN make install

FROM mcr.microsoft.com/dotnet/sdk:$SDK_VERSION

# For GSS-NTLMSSP
RUN apk add --no-cache libunistring

RUN mkdir -p /usr/etc/gss/mech.d \
    && echo "# NTLMSSP mechanism plugin"                                                                                      > /usr/etc/gss/mech.d/mech.ntlmssp.conf \
    && echo "# Mechanism Name	Object Identifier		Shared Library Path			Other Options"       >> /usr/etc/gss/mech.d/mech.ntlmssp.conf \
    && echo "gssntlmssp_v1		1.3.6.1.4.1.311.2.2.10	        /usr/local/lib/gssntlmssp/gssntlmssp.so"             >> /usr/etc/gss/mech.d/mech.ntlmssp.conf

COPY --from=gss_ntlm /usr/local/lib/gssntlmssp/gssntlmssp.so /usr/local/lib/gssntlmssp/gssntlmssp.so

WORKDIR /src

COPY ./ntlm-test.ps1 .

ARG ENABLE_OPENSSL_LEGACY="true"

RUN if [ "${ENABLE_OPENSSL_LEGACY:-}" = "true" ]; then \
        # Add reference to 'legacy_sect' after the default section reference \
        \
        sed -i -r '/^default = default_sect$/a legacy = legacy_sect'   /etc/ssl/openssl.cnf \
        # Activate default section after the [default_sect] line
        \
        && sed -i -r '/^\[default_sect\]$/a activate = 1'              /etc/ssl/openssl.cnf \
        # Add the rest of the lines to the end of the file \
        && echo ''                                                  >> /etc/ssl/openssl.cnf \
        && echo '[legacy_sect]'                                     >> /etc/ssl/openssl.cnf \
        && echo 'activate = 1'                                      >> /etc/ssl/openssl.cnf \
        ; \
    else \
        echo "Not enabling OpenSSL legacy config as 'ENABLE_OPENSSL_LEGACY' is not set to 'true'" \
        ; \
    fi

ENV GSSNTLMSSP_DEBUG=/tmp/ntlm_debug

ENTRYPOINT ["/usr/bin/pwsh"]

CMD ["-Command", "/src/ntlm-test.ps1"]
