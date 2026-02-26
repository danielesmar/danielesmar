(function () {
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (prefersDark) {
      document.body.setAttribute("data-theme", "dark");
  }
})();