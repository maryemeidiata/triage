/** @type {import('@sveltejs/kit').Config} */
const config = {
  kit: {
    prerender: {
      handleMissingId: 'warn',
      handleHttpError: ({ path, referrer, message }) => {
        if (path.startsWith('/hospital/')) return;
        throw new Error(message);
      }
    }
  }
};

export default config;
