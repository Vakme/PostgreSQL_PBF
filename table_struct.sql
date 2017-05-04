CREATE TABLE "blacklist" (
  "id" SERIAL PRIMARY KEY
);

CREATE TABLE "forum" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL,
  "permission_level" TEXT NOT NULL,
  "post_number" INTEGER NOT NULL,
  "topic_number" INTEGER NOT NULL
);

CREATE TABLE "user" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT UNIQUE,
  "password" TEXT NOT NULL,
  "age" INTEGER,
  "gender" TEXT NOT NULL,
  "appearance" TEXT NOT NULL,
  "character" TEXT NOT NULL,
  "history" TEXT NOT NULL,
  "health" INTEGER,
  "avatar" TEXT NOT NULL,
  "permission_level" INTEGER NOT NULL,
  "blacklist" INTEGER
);

CREATE INDEX "idx_user__blacklist" ON "user" ("blacklist");

ALTER TABLE "user" ADD CONSTRAINT "fk_user__blacklist" FOREIGN KEY ("blacklist") REFERENCES "blacklist" ("id");

CREATE TABLE "privatemessage" (
  "id" SERIAL PRIMARY KEY,
  "sender" INTEGER NOT NULL,
  "receiver" INTEGER NOT NULL,
  "title" TEXT NOT NULL,
  "content" TEXT NOT NULL
);

CREATE INDEX "idx_privatemessage__receiver" ON "privatemessage" ("receiver");

CREATE INDEX "idx_privatemessage__sender" ON "privatemessage" ("sender");

ALTER TABLE "privatemessage" ADD CONSTRAINT "fk_privatemessage__receiver" FOREIGN KEY ("receiver") REFERENCES "user" ("id");

ALTER TABLE "privatemessage" ADD CONSTRAINT "fk_privatemessage__sender" FOREIGN KEY ("sender") REFERENCES "user" ("id");

CREATE TABLE "stats" (
  "id" SERIAL PRIMARY KEY,
  "user" INTEGER NOT NULL,
  "strength" INTEGER NOT NULL,
  "agility" INTEGER NOT NULL,
  "durability" INTEGER NOT NULL,
  "intelligence" INTEGER NOT NULL,
  "wisdom" INTEGER NOT NULL,
  "charisma" INTEGER NOT NULL
);

CREATE INDEX "idx_stats__user" ON "stats" ("user");

ALTER TABLE "stats" ADD CONSTRAINT "fk_stats__user" FOREIGN KEY ("user") REFERENCES "user" ("id");

CREATE TABLE "topic" (
  "id" SERIAL PRIMARY KEY,
  "forum" INTEGER NOT NULL,
  "owner" INTEGER NOT NULL,
  "name" TEXT NOT NULL
);

CREATE INDEX "idx_topic__forum" ON "topic" ("forum");

CREATE INDEX "idx_topic__owner" ON "topic" ("owner");

ALTER TABLE "topic" ADD CONSTRAINT "fk_topic__forum" FOREIGN KEY ("forum") REFERENCES "forum" ("id");

ALTER TABLE "topic" ADD CONSTRAINT "fk_topic__owner" FOREIGN KEY ("owner") REFERENCES "user" ("id");

CREATE TABLE "post" (
  "id" SERIAL PRIMARY KEY,
  "topic" INTEGER NOT NULL,
  "user" INTEGER NOT NULL,
  "content" TEXT NOT NULL,
  "defence" BOOLEAN,
  "result" TEXT NOT NULL,
  "attack" INTEGER
);

CREATE INDEX "idx_post__attack" ON "post" ("attack");

CREATE INDEX "idx_post__topic" ON "post" ("topic");

CREATE INDEX "idx_post__user" ON "post" ("user");

ALTER TABLE "post" ADD CONSTRAINT "fk_post__attack" FOREIGN KEY ("attack") REFERENCES "user" ("id");

ALTER TABLE "post" ADD CONSTRAINT "fk_post__topic" FOREIGN KEY ("topic") REFERENCES "topic" ("id");

ALTER TABLE "post" ADD CONSTRAINT "fk_post__user" FOREIGN KEY ("user") REFERENCES "user" ("id");

CREATE TABLE "weapon" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL,
  "level" INTEGER NOT NULL,
  "strength" INTEGER NOT NULL,
  "user" INTEGER NOT NULL
);

CREATE INDEX "idx_weapon__user" ON "weapon" ("user");

ALTER TABLE "weapon" ADD CONSTRAINT "fk_weapon__user" FOREIGN KEY ("user") REFERENCES "user" ("id")
