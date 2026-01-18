# ========== BUILD STAGE ==========
FROM gradle:8.5-jdk21-alpine AS build

WORKDIR /app

# Copy gradle wrapper & config first (for cache)
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle settings.gradle ./

RUN chmod +x gradlew
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src ./src

# Build
RUN ./gradlew clean build -x test --no-daemon


# ========== RUNTIME STAGE ==========
FROM eclipse-temurin:21-jre-alpine

RUN apk add --no-cache wget

WORKDIR /app

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy jar
COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Support JAVA_OPTS
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
