FROM alpine:3.23 AS builder

ARG KCCTL_VERSION=1.0.0.CR4
ARG TARGETARCH

RUN ARCH=$(case ${TARGETARCH} in \
        "amd64") echo "x86_64" ;; \
        "arm64") echo "aarch64" ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac) && \
    apk add --no-cache curl unzip && \
    curl -L "https://github.com/kcctl/kcctl/releases/download/v${KCCTL_VERSION}/kcctl-${KCCTL_VERSION}-linux-${ARCH}.zip" -o /tmp/kcctl.zip && \
    unzip /tmp/kcctl.zip -d /tmp && \
    mv /tmp/kcctl-${KCCTL_VERSION}-linux-${ARCH}/bin/kcctl /usr/local/bin/kcctl && \
    chmod +x /usr/local/bin/kcctl

FROM gcr.io/distroless/base-debian13:nonroot

LABEL org.opencontainers.image.source=https://github.com/createdna/dockerfiles

COPY --from=builder /usr/local/bin/kcctl /usr/local/bin/kcctl

ENTRYPOINT ["/usr/local/bin/kcctl"]
CMD ["--help"]
