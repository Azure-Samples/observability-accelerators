FROM mcr.microsoft.com/openjdk/jdk:17-ubuntu as base


FROM maven:3.8.5-openjdk-17-slim as build
WORKDIR /src

RUN mvn -version

COPY pom.xml .
RUN mvn -B dependency:resolve-plugins dependency:resolve
# RUN mvn -B dependency:go-offline

COPY . .
RUN mvn package

RUN ls -al target
RUN ls -al target/dependency

FROM base as final
COPY applicationinsights.json applicationinsights.json

ARG JAR_FILE=/src/target/*.jar
ARG DEPENDENCY=/src/target/dependency
COPY --from=build ${DEPENDENCY}/applicationinsights-agent-3.4.7.jar applicationinsights-agent-3.4.7.jar
COPY --from=build ${JAR_FILE} app.jar

ENTRYPOINT ["java", "-javaagent:applicationinsights-agent-3.4.7.jar" ,"-jar","/app.jar" ]
