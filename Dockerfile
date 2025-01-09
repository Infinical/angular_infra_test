# Stage 1: Build the Angular app
FROM node:18 AS build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the entire project
COPY . .

# Build the Angular app with SSR
RUN npm run build

# Stage 2: Run the Angular SSR server
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy the built app from the previous stage
COPY --from=build /app/dist/kyosk_test/ /app/dist

# Install only production dependencies
COPY package*.json ./
RUN npm install --production

# Expose the server port
EXPOSE 4000

# Run the Angular SSR server
CMD ["node", "dist/server/server.mjs"]
