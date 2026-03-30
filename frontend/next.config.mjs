/** @type {import('next').NextConfig} */
const nextConfig = {
  reactCompiler: true,
  // Map `BASE_URL` from frontend/.env into the client bundle as NEXT_PUBLIC_BASE_URL.
  env: {
    NEXT_PUBLIC_BASE_URL: (
      process.env.BASE_URL ||
      process.env.NEXT_PUBLIC_BASE_URL ||
      ""
    )
      .trim()
      .replace(/\/$/, ""),
  },
};

export default nextConfig;
