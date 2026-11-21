import { assertEquals } from "jsr:@std/assert@1";
import { addressOf, fromWithName, loadTemplate, renderMergeTags, templateKey, usableRow, usesSchool } from "./template.ts";

Deno.test("greeting matches the original opening line", () => {
  assertEquals(renderMergeTags("{greeting}\n\nthis is ali", { firstName: "Sam" }), "hi sam.\n\nthis is ali");
  assertEquals(renderMergeTags("{greeting}", { firstName: null }), "hi.");
});

Deno.test("first name and school fall back", () => {
  assertEquals(renderMergeTags("hi {first_name}", {}), "hi there");
  assertEquals(renderMergeTags("hi {first_name|friend}", {}), "hi friend");
  assertEquals(renderMergeTags("at {school}", { school: "UConn" }), "at UConn");
  assertEquals(usesSchool("at {school|}"), true);
  assertEquals(usesSchool("hi {first_name}"), false);
});

Deno.test("template keys", () => {
  assertEquals(templateKey("free", false), "founder_free");
  assertEquals(templateKey("paid", false), "founder_paid");
  assertEquals(templateKey("paid", true), "founder_paid_upgrade");
});

Deno.test("from header keeps the configured address", () => {
  assertEquals(addressOf("Ali Mirza <ali@notification.getrounds.app>"), "ali@notification.getrounds.app");
  assertEquals(fromWithName("Ali Mirza <ali@notification.getrounds.app>", "Ali from Rounds"), "Ali from Rounds <ali@notification.getrounds.app>");
  assertEquals(fromWithName("ali@notification.getrounds.app", ""), "ali@notification.getrounds.app");
  assertEquals(fromWithName("x <a@b.co>", 'Bad "<name>"'), "Bad name <a@b.co>");
});

Deno.test("unusable rows read as missing", () => {
  assertEquals(usableRow(null), null);
  assertEquals(usableRow({ subject: " ", body: "x", enabled: true }), null);
  assertEquals(usableRow({ subject: "s", body: "b", from_name: null, reply_to: "not-an-email", enabled: false }), {
    subject: "s", body: "b", from_name: null, reply_to: null, enabled: false,
  });
});

function fakeAdmin(result: { data?: unknown; error?: { message: string } | null; throws?: boolean }) {
  const chain = {
    select: () => chain,
    eq: () => chain,
    maybeSingle: () => (result.throws ? Promise.reject(new Error("boom")) : Promise.resolve({ data: result.data ?? null, error: result.error ?? null })),
  };
  return { from: () => chain };
}

Deno.test("loadTemplate falls back on a missing table, a missing row, or a throw", async () => {
  assertEquals(await loadTemplate(fakeAdmin({ error: { message: 'relation "email_templates" does not exist' } }), "founder_free"), null);
  assertEquals(await loadTemplate(fakeAdmin({ data: null }), "founder_free"), null);
  assertEquals(await loadTemplate(fakeAdmin({ throws: true }), "founder_free"), null);
  const row = await loadTemplate(fakeAdmin({ data: { subject: "s", body: "b", from_name: "Ali", reply_to: "a@b.co", enabled: true } }), "founder_free");
  assertEquals(row?.from_name, "Ali");
});
