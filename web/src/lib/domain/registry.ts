// The book registry, read from catalog/scripture/books.json and checked as
// Swift's BookRegistry checks it (docs/decisions.md E27, docs/engine.md).
import { isBookID, type BookID } from "./ids.ts";

/** The ways of naming the books a reader can choose from (D29). */
export const namingConventions = ["common", "kjv", "douay"] as const;
export type NamingConvention = (typeof namingConventions)[number];

export type Testament = "old" | "new";

export interface BookName {
  name: string;
  abbreviation?: string;
}

export interface Book {
  id: BookID;
  testament: Testament;
  /** The common English name. */
  commonName: BookName;
  /** The names a convention gives where it differs from the common one. */
  otherNames: Partial<Record<NamingConvention, BookName>>;
  note?: string;
}

export interface Order {
  id: string;
  label: string;
  books: BookID[];
  sources: string[];
}

export interface Canon {
  id: string;
  label: string;
  description: string;
  /** Every order lists the same books; the first is the canon's own. */
  orders: Order[];
  /** Material a listed book contains that other Bibles print apart. */
  includes: Partial<Record<BookID, BookID[]>>;
  includesSources: string[];
}

export interface Convention {
  id: NamingConvention;
  label: string;
  example: string;
  rule: string;
  sources: string[];
}

export interface Source {
  id: string;
  title: string;
  publisher: string;
  url: string;
  alsoChecked?: string;
  checked: string;
  usedFor: string;
}

export type BookRegistryErrorKind =
  | "unreadable"
  | "unsupportedFormat"
  | "duplicateConvention"
  | "missingConvention"
  | "duplicateBook"
  | "emptyName"
  | "redundantName"
  | "duplicateName"
  | "duplicateAbbreviation"
  | "duplicateCanon"
  | "duplicateOrder"
  | "canonWithoutOrder"
  | "unknownBook"
  | "repeatedBook"
  | "ordersDisagree"
  | "testamentsMixed"
  | "includedTwice"
  | "unsourcedIncludes"
  | "bookInNoCanon"
  | "duplicateSource"
  | "unknownSource"
  | "unusedSource";

/** A problem in the book registry; the message is Swift's wording. */
export class BookRegistryError extends Error {
  override name = "BookRegistryError";
  readonly kind: BookRegistryErrorKind;
  constructor(kind: BookRegistryErrorKind, message: string) {
    super(message);
    this.kind = kind;
  }
}

/** The registry format this build reads. */
export const registryFormat = 1;

/** A book's name under a convention: its own name there, or the common one. */
export function bookName(book: Book, convention: NamingConvention): BookName {
  return book.otherNames[convention] ?? book.commonName;
}

/** The books a canon lists, in its first order. */
export function canonBooks(canon: Canon): BookID[] {
  return canon.orders[0]?.books ?? [];
}

/** The listed book that holds this material, if the canon includes it inside another. */
export function bookIncluding(canon: Canon, book: BookID): BookID | undefined {
  for (const [holder, parts] of Object.entries(canon.includes)) {
    if (parts?.includes(book)) return holder;
  }
  return undefined;
}

/** Whether the canon has this book, as a book of its own or inside one. */
export function canonContains(canon: Canon, book: BookID): boolean {
  return canonBooks(canon).includes(book) || bookIncluding(canon, book) !== undefined;
}

export class BookRegistry {
  readonly conventions: Convention[];
  readonly books: Book[];
  readonly canons: Canon[];
  readonly sources: Source[];
  readonly #index: Map<BookID, Book>;

  /** Reads and checks a registry, throwing the first problem found. */
  constructor(json: string) {
    const file = decodeFile(json);
    if (file.format !== registryFormat) {
      fail("unsupportedFormat", `format ${file.format} is not format ${registryFormat}`);
    }

    const sourceIDs = unique(
      file.sources.map((s) => s.id),
      (id) => fail("duplicateSource", `the source ${id} is described twice`),
    );
    const usedSources = new Set<string>();
    const checkSources = (ids: string[], place: string) => {
      for (const id of ids) {
        if (!sourceIDs.has(id)) {
          fail("unknownSource", `${place} cites ${id}, which is not described`);
        }
        usedSources.add(id);
      }
    };

    unique(
      file.conventions.map((c) => c.id),
      (id) => fail("duplicateConvention", `the convention ${id} is described twice`),
    );
    for (const convention of namingConventions) {
      if (!file.conventions.some((c) => c.id === convention)) {
        fail("missingConvention", `the convention ${convention} is not described`);
      }
    }
    for (const convention of file.conventions) checkSources(convention.sources, convention.id);

    const bookIDs = unique(
      file.books.map((b) => b.id),
      (id) => fail("duplicateBook", `${id} is registered twice`),
    );
    const books: Book[] = file.books.map((entry) => {
      const common: BookName = withAbbreviation(entry.name, entry.abbreviation);
      const others = entry.names ?? {};
      for (const name of [common, ...Object.values(others)]) {
        if (name.name === "" || name.abbreviation === "") {
          fail("emptyName", `${entry.id} has an empty name or abbreviation`);
        }
      }
      for (const [convention, name] of Object.entries(others) as [NamingConvention, BookName][]) {
        if (sameName(name, common) || convention === "common") {
          fail(
            "redundantName",
            `${entry.id}'s ${convention} name repeats its common name or is not another convention's`,
          );
        }
      }
      const book: Book = {
        id: entry.id,
        testament: entry.testament,
        commonName: common,
        otherNames: others,
      };
      if (entry.note !== undefined) book.note = entry.note;
      return book;
    });

    for (const convention of namingConventions) {
      const names = new Set<string>();
      const abbreviations = new Set<string>();
      for (const book of books) {
        const name = bookName(book, convention);
        const lowered = name.name.toLowerCase();
        if (names.has(lowered)) {
          fail("duplicateName", `two books are called "${name.name}" in ${convention}`);
        }
        names.add(lowered);
        if (name.abbreviation !== undefined) {
          const abbreviation = name.abbreviation.toLowerCase();
          if (abbreviations.has(abbreviation)) {
            fail(
              "duplicateAbbreviation",
              `two books are abbreviated "${name.abbreviation}" in ${convention}`,
            );
          }
          abbreviations.add(abbreviation);
        }
      }
    }

    const testaments = new Map(books.map((b) => [b.id, b.testament]));
    const usedBooks = new Set<BookID>();
    unique(
      file.canons.map((c) => c.id),
      (id) => fail("duplicateCanon", `the canon ${id} is described twice`),
    );
    unique(
      file.canons.flatMap((c) => c.orders.map((o) => o.id)),
      (id) => fail("duplicateOrder", `the order ${id} is described twice`),
    );
    const canons: Canon[] = file.canons.map((entry) => {
      const first = entry.orders[0];
      if (!first) fail("canonWithoutOrder", `the canon ${entry.id} has no order`);
      const firstBooks = new Set(first.books);
      const orders = entry.orders.map((order) => {
        unique(order.books, (book) =>
          fail("repeatedBook", `the order ${order.id} lists ${book} twice`),
        );
        for (const book of order.books) {
          if (!bookIDs.has(book)) {
            fail("unknownBook", `${order.id} names ${book}, which is not registered or not listed`);
          }
        }
        if (
          order.books.length !== firstBooks.size ||
          !order.books.every((b) => firstBooks.has(b))
        ) {
          fail(
            "ordersDisagree",
            `the order ${order.id} lists other books than the canon ${entry.id}`,
          );
        }
        let index = 0;
        while (index < order.books.length && testaments.get(order.books[index] ?? "") === "old") {
          index += 1;
        }
        if (!order.books.slice(index).every((b) => testaments.get(b) === "new")) {
          fail(
            "testamentsMixed",
            `the order ${order.id} puts an Old Testament book after a New Testament one`,
          );
        }
        checkSources(order.sources, order.id);
        for (const book of order.books) usedBooks.add(book);
        return { id: order.id, label: order.label, books: order.books, sources: order.sources };
      });
      const includes = entry.includes ?? {};
      const included = new Set<BookID>();
      for (const [book, parts] of Object.entries(includes)) {
        if (!firstBooks.has(book)) {
          fail("unknownBook", `${entry.id} names ${book}, which is not registered or not listed`);
        }
        for (const part of parts ?? []) {
          if (!bookIDs.has(part)) {
            fail("unknownBook", `${entry.id} names ${part}, which is not registered or not listed`);
          }
          if (firstBooks.has(part) || included.has(part)) {
            fail("includedTwice", `the canon ${entry.id} has ${part} twice`);
          }
          included.add(part);
        }
      }
      for (const book of included) usedBooks.add(book);
      if (Object.keys(includes).length > 0 && (entry.includesSources ?? []).length === 0) {
        fail("unsourcedIncludes", `the canon ${entry.id}'s included material has no source`);
      }
      checkSources(entry.includesSources ?? [], entry.id);
      return {
        id: entry.id,
        label: entry.label,
        description: entry.description,
        orders,
        includes,
        includesSources: entry.includesSources ?? [],
      };
    });

    const unusedBook = books.find((b) => !usedBooks.has(b.id));
    if (unusedBook) fail("bookInNoCanon", `${unusedBook.id} belongs to no canon`);
    const unusedSource = file.sources.find((s) => !usedSources.has(s.id));
    if (unusedSource) fail("unusedSource", `the source ${unusedSource.id} is cited by nothing`);

    this.conventions = file.conventions;
    this.books = books;
    this.canons = canons;
    this.sources = file.sources;
    this.#index = new Map(books.map((b) => [b.id, b]));
  }

  book(id: BookID): Book | undefined {
    return this.#index.get(id);
  }

  canon(id: string): Canon | undefined {
    return this.canons.find((c) => c.id === id);
  }

  /** The canons that have this book, as a book of its own or inside another. */
  canonsContaining(book: BookID): Canon[] {
    return this.canons.filter((c) => canonContains(c, book));
  }
}

function fail(kind: BookRegistryErrorKind, message: string): never {
  throw new BookRegistryError(kind, message);
}

/** The values as a set, failing for the first one that repeats. */
function unique<T>(values: T[], repeated: (value: T) => never): Set<T> {
  const seen = new Set<T>();
  for (const value of values) {
    if (seen.has(value)) repeated(value);
    seen.add(value);
  }
  return seen;
}

function withAbbreviation(name: string, abbreviation: string | undefined): BookName {
  return abbreviation === undefined ? { name } : { name, abbreviation };
}

function sameName(a: BookName, b: BookName): boolean {
  return a.name === b.name && a.abbreviation === b.abbreviation;
}

// The file's shape, decoded before it is checked, as Swift's JSONDecoder
// does: unknown keys are ignored, a missing or mistyped field is unreadable.

interface File {
  format: number;
  conventions: Convention[];
  books: {
    id: BookID;
    testament: Testament;
    name: string;
    abbreviation?: string;
    names?: Partial<Record<NamingConvention, BookName>>;
    note?: string;
  }[];
  canons: {
    id: string;
    label: string;
    description: string;
    includes?: Partial<Record<BookID, BookID[]>>;
    includesSources?: string[];
    orders: Order[];
  }[];
  sources: Source[];
}

type Json = unknown;

function unreadable(detail: string): never {
  fail("unreadable", `the registry is not valid JSON of the expected shape: ${detail}`);
}

function object(value: Json, at: string): Record<string, Json> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    unreadable(`${at} is not an object`);
  }
  return value as Record<string, Json>;
}

function list(value: Json, at: string): Json[] {
  if (!Array.isArray(value)) unreadable(`${at} is not a list`);
  return value;
}

function text(value: Json, at: string): string {
  if (typeof value !== "string") unreadable(`${at} is not a string`);
  return value;
}

function optionalText(value: Json, at: string): string | undefined {
  return value === undefined || value === null ? undefined : text(value, at);
}

function whole(value: Json, at: string): number {
  if (typeof value !== "number" || !Number.isInteger(value)) unreadable(`${at} is not a number`);
  return value;
}

function texts(value: Json, at: string): string[] {
  return list(value, at).map((item, i) => text(item, `${at}[${i}]`));
}

function bookID(value: Json, at: string): BookID {
  const id = text(value, at);
  if (!isBookID(id)) unreadable(`${at} is not a book id: ${id}`);
  return id;
}

function bookIDs(value: Json, at: string): BookID[] {
  return list(value, at).map((item, i) => bookID(item, `${at}[${i}]`));
}

function convention(value: Json, at: string): NamingConvention {
  const id = text(value, at);
  if (!(namingConventions as readonly string[]).includes(id)) {
    unreadable(`${at} is not a naming convention: ${id}`);
  }
  return id as NamingConvention;
}

function name(value: Json, at: string): BookName {
  const entry = object(value, at);
  return withAbbreviation(
    text(entry["name"], `${at}.name`),
    optionalText(entry["abbreviation"], `${at}.abbreviation`),
  );
}

function decodeFile(json: string): File {
  let root: Json;
  try {
    root = JSON.parse(json);
  } catch (error) {
    unreadable(error instanceof Error ? error.message : String(error));
  }
  const file = object(root, "the registry");
  return {
    format: whole(file["format"], "format"),
    conventions: list(file["conventions"], "conventions").map((value, i) => {
      const at = `conventions[${i}]`;
      const entry = object(value, at);
      return {
        id: convention(entry["id"], `${at}.id`),
        label: text(entry["label"], `${at}.label`),
        example: text(entry["example"], `${at}.example`),
        rule: text(entry["rule"], `${at}.rule`),
        sources: texts(entry["sources"], `${at}.sources`),
      };
    }),
    books: list(file["books"], "books").map((value, i) => {
      const at = `books[${i}]`;
      const entry = object(value, at);
      const testament = text(entry["testament"], `${at}.testament`);
      if (testament !== "old" && testament !== "new") {
        unreadable(`${at}.testament is not old or new`);
      }
      const book: File["books"][number] = {
        id: bookID(entry["id"], `${at}.id`),
        testament,
        name: text(entry["name"], `${at}.name`),
      };
      const abbreviation = optionalText(entry["abbreviation"], `${at}.abbreviation`);
      if (abbreviation !== undefined) book.abbreviation = abbreviation;
      if (entry["names"] !== undefined && entry["names"] !== null) {
        const names: Partial<Record<NamingConvention, BookName>> = {};
        for (const [key, named] of Object.entries(object(entry["names"], `${at}.names`))) {
          names[convention(key, `${at}.names key`)] = name(named, `${at}.names.${key}`);
        }
        book.names = names;
      }
      const note = optionalText(entry["note"], `${at}.note`);
      if (note !== undefined) book.note = note;
      return book;
    }),
    canons: list(file["canons"], "canons").map((value, i) => {
      const at = `canons[${i}]`;
      const entry = object(value, at);
      const canon: File["canons"][number] = {
        id: text(entry["id"], `${at}.id`),
        label: text(entry["label"], `${at}.label`),
        description: text(entry["description"], `${at}.description`),
        orders: list(entry["orders"], `${at}.orders`).map((orderValue, j) => {
          const orderAt = `${at}.orders[${j}]`;
          const order = object(orderValue, orderAt);
          return {
            id: text(order["id"], `${orderAt}.id`),
            label: text(order["label"], `${orderAt}.label`),
            sources: texts(order["sources"], `${orderAt}.sources`),
            books: bookIDs(order["books"], `${orderAt}.books`),
          };
        }),
      };
      if (entry["includes"] !== undefined && entry["includes"] !== null) {
        const includes: Partial<Record<BookID, BookID[]>> = {};
        for (const [key, parts] of Object.entries(object(entry["includes"], `${at}.includes`))) {
          includes[bookID(key, `${at}.includes key`)] = bookIDs(parts, `${at}.includes.${key}`);
        }
        canon.includes = includes;
      }
      if (entry["includesSources"] !== undefined && entry["includesSources"] !== null) {
        canon.includesSources = texts(entry["includesSources"], `${at}.includesSources`);
      }
      return canon;
    }),
    sources: list(file["sources"], "sources").map((value, i) => {
      const at = `sources[${i}]`;
      const entry = object(value, at);
      const source: Source = {
        id: text(entry["id"], `${at}.id`),
        title: text(entry["title"], `${at}.title`),
        publisher: text(entry["publisher"], `${at}.publisher`),
        url: text(entry["url"], `${at}.url`),
        checked: text(entry["checked"], `${at}.checked`),
        usedFor: text(entry["usedFor"], `${at}.usedFor`),
      };
      const alsoChecked = optionalText(entry["alsoChecked"], `${at}.alsoChecked`);
      if (alsoChecked !== undefined) source.alsoChecked = alsoChecked;
      return source;
    }),
  };
}
