ARG ARCH=""
FROM ${ARCH}alpine as builder

RUN apk add --update ca-certificates gcc build-base tzdata libc6-compat
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN set -x \
    && mkdir -p rootfs/lib \
    && set -- \
        /etc/nsswitch.conf \
        /etc/ssl/certs/ca-certificates.crt \
        /usr/share/zoneinfo \
        /etc/services \
        /lib/"$(gcc -print-multiarch)"/libpthread.so.* \
    && while [ "$#" -gt 0  ]; do \
        f="$1"; shift; \
        fn="$(basename "$f")"; \
        if [ -e "rootfs/lib/$fn" ]; then continue; fi; \
        if [ "${f#/lib/}" != "$f" ]; then \
            ln -vn "$f" "rootfs/lib/$fn"; \
        else \
            d="$(dirname $f)" \
            && mkdir -p "rootfs/${d#/}" \
            && cp -av "$f" "rootfs/${f#/}"; \
        fi; \
    done

FROM ${ARCH}alpine
COPY --from=builder /rootfs /rootfs