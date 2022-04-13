FROM mwaeckerlin/very-base as build
RUN $PKG_INSTALL docker

FROM mwaeckerlin/scratch
ENV CONTAINERNAME="dockindock"
COPY --from=build / /
USER root
CMD dockerd
