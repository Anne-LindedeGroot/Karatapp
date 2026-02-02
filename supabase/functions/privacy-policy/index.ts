const publicUrl =
  "https://anne-lindedegroot.github.io/Karatapp/privacy_policy.html";

Deno.serve(() => {
  return new Response(null, {
    status: 302,
    headers: {
      location: publicUrl,
      "cache-control": "no-store",
      "x-privacy-policy-version": "v6-redirect-github",
    },
  });
});
