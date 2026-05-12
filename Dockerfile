# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.26.2
ARG RUNTIME_IMAGE=gcr.io/distroless/static-debian12:nonroot

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-bookworm AS deps
WORKDIR /src

ENV CGO_ENABLED=0

COPY .go-version go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    expected="$(cat .go-version)" && \
    actual="$(go env GOVERSION | sed 's/^go//')" && \
    if [ "${expected}" != "${actual}" ]; then \
      echo "Go builder version ${actual} does not match .go-version ${expected}" >&2; \
      exit 1; \
    fi && \
    go mod download

FROM deps AS source
COPY . .

FROM source AS test
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -mod=readonly ./...

FROM source AS build
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
ARG COMMIT=none
ARG DATE=unknown

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go build \
      -mod=readonly \
      -trimpath \
      -buildvcs=false \
      -ldflags="-s -w -buildid= -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" \
      -o /out/template-go \
      ./cmd/template-go

FROM ${RUNTIME_IMAGE} AS runtime
ARG VERSION=dev
ARG COMMIT=none
ARG SOURCE=https://github.com/meigma/template-go

LABEL org.opencontainers.image.title="template-go" \
      org.opencontainers.image.description="Meigma Go repository template application" \
      org.opencontainers.image.source="${SOURCE}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT}"

USER 65532:65532
COPY --from=build /out/template-go /usr/local/bin/template-go
ENTRYPOINT ["/usr/local/bin/template-go"]
