/** @type {import('next').NextConfig} */
const nextConfig = {
    // Required for the production Docker image (node server.js)
    output: "standalone",
};

module.exports = nextConfig;
