# Node.js image is used
FROM node:20-alpine

# Working directory inside the container
WORKDIR /usr/src/app

# Copying package.json and package-lock.json to install dependencies
COPY package*.json ./

# Install Dependencies
RUN npm install

# Copying the rest of the application code
COPY . .

# Assembly of the project
RUN npm run build

# Specifying the port for the application to run
EXPOSE 3000

# Run command for production mode
CMD ["npm", "run", "s"]