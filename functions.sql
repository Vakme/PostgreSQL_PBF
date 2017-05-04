-- 3.3.1 - Wyświetlanie danych

CREATE VIEW displayForum AS SELECT * FROM forum ORDER BY id;

CREATE OR REPLACE FUNCTION displayTopics(integer) RETURNS TABLE(tid integer, tname text, uname text, uid integer) AS'
SELECT t.id, t.name, "user".name, "user".id FROM "user", topic t, forum f WHERE t.forum = f.id AND t.owner="user".id AND f.id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION selectPosts(integer) RETURNS TABLE(pid integer, pcontent text, pdefence boolean, presult text, uid integer, uname text, attackedname text, tname text, uavatar text, pdate timestamp without time zone, uhealth integer) AS'
SELECT p.id, p.content, p.defence, p.result, u1.id, u1.name, (SELECT coalesce(u2.name, ''Nikt'') FROM "user" u2 WHERE p.topic = t.id AND p.attack = u2.id) as u2name, t.name, u1.avatar, p.publish_date, u1.health FROM post p, "user" u1, topic t WHERE p.topic = t.id AND p.user = u1.id AND t.id = $1 ORDER BY p.publish_date;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION displayUser(integer) RETURNS "user" AS'
SELECT * FROM "user" WHERE "user".id = $1;
'LANGUAGE SQL;

CREATE VIEW show_users AS SELECT * FROM "user";

CREATE OR REPLACE FUNCTION displayUserPosts(integer) RETURNS TABLE(postid integer, postcontent text, postdefence boolean, postresult text, userid integer, username text, attackname text, topicname text, topicid integer) AS'
SELECT p.id, p.content, p.defence, p.result, u1.id, u1.name, u2.name, t.name, t.id FROM post p, "user" u1, "user" u2, topic t WHERE p.topic = t.id AND p.user = u1.id AND (p.attack = u2.id OR p.attack IS NULL) AND u1.id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION displayUserStats(integer) RETURNS stats AS'
SELECT * FROM stats s WHERE s.user = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION displayUserTopics(integer) RETURNS  TABLE(topicname text, topicid integer) AS'
SELECT t.name, t.id FROM "user" u, topic t WHERE t.owner = u.id AND u.id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION displayUserWeapon(integer) RETURNS weapon AS'
SELECT * FROM weapon s WHERE s.user = $1
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION selectReceiver(senderId integer) RETURNS TABLE (uid integer, uname text) AS '
SELECT u.id, u.name FROM "user" u WHERE u.id <> senderId ORDER BY u.id;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION showSended(senderName text) RETURNS setof record LANGUAGE plpgsql AS '
DECLARE
userId integer;
returnrec RECORD;
BEGIN
SELECT * FROM selectID($1) INTO userId;
FOR returnrec IN SELECT u.id, u.name, m.title, m.content FROM "user" u, privatemessage m WHERE m.sender = userId AND u.id = m.receiver LOOP
        RETURN NEXT returnrec;
    END LOOP;
END;
';

CREATE OR REPLACE FUNCTION showReceived(senderName text) RETURNS setof record LANGUAGE plpgsql AS '
DECLARE
userId integer;
returnrec RECORD;
BEGIN
SELECT * FROM selectID($1) INTO userId;
FOR returnrec IN SELECT u.id, u.name, m.title, m.content FROM "user" u, privatemessage m WHERE m.receiver = userId AND u.id = m.sender LOOP
        RETURN NEXT returnrec;
    END LOOP;
END;
';

-- 3.3.2 - Rejestracja i logowanie

CREATE OR REPLACE FUNCTION selectPerms(userName text) RETURNS integer AS '
SELECT u.permission_level FROM "user" u WHERE u.name = userName;
'LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION login(name text, password text) RETURNS bool LANGUAGE plpgsql AS 'DECLARE 
rownm INTEGER;      
namevar TEXT;
passvar TEXT;
BEGIN      
SELECT regexp_replace($1, ''\;|\(\)'', '''', ''g'') INTO namevar;
SELECT regexp_replace($2, ''\;'', '''', ''g'') INTO passvar;     
SELECT ROW_NUMBER() INTO rownm OVER(ORDER BY u.id) FROM "user" u WHERE u.name = namevar AND u.password = md5(passvar);
IF rownm = 1 THEN                                          
RETURN TRUE; 
END IF;    
RETURN FALSE;
END;  ';

CREATE OR REPLACE FUNCTION register(name text, password text, age integer, gender text, appearance text, charact text, history text, avatar text, weapon text, stats bool) RETURNS bool LANGUAGE plpgsql AS 'DECLARE 
userId INTEGER;      
namevar TEXT;
passvar TEXT;
gendervar TEXT;
appearancevar TEXT;
charactervar TEXT;
historyvar TEXT;
avatarvar TEXT;
weaponvar TEXT;
statId INTEGER;
wId INTEGER;
BEGIN      
SELECT regexp_replace($1, ''\;|\(\)'', '''', ''g'') INTO namevar;
SELECT regexp_replace($2, ''\;'', '''', ''g'') INTO passvar; 
SELECT regexp_replace($4, ''\;|\(\)'', '''', ''g'') INTO gendervar;
SELECT regexp_replace($5, ''\;'', '''', ''g'') INTO appearancevar; 
SELECT regexp_replace($6, ''\;'', '''', ''g'') INTO charactervar; 
SELECT regexp_replace($7, ''\;'', '''', ''g'') INTO historyvar;   
SELECT regexp_replace($9, ''\;'', '''', ''g'') INTO weaponvar;   
SELECT regexp_replace($8, ''\;|\(\)'', '''', ''g'') INTO avatarvar;  
SELECT nextval(''user_id_seq'') INTO userId;
INSERT INTO "user" (id, name, age, gender, appearance, character, history, health, permission_level, avatar, password) VALUES(userId, namevar, $3, gendervar, appearancevar, charactervar, historyvar, 100, 2, avatarvar, md5(passvar));

SELECT nextval(''stats_id_seq'') INTO statId;
SEL
IF stats THEN 
INSERT INTO stats (id, "user", strength, agility, durability, intelligence, wisdom, charisma) VALUES(statId, userId, trunc(random() * (6-1) + 1), trunc(random() * (6-1) + 1), trunc(random() * (6-1) + 1), trunc(random() * (6-1) + 1), trunc(random() * (6-1) + 1), trunc(random() * (6-1) + 1));
ELSE 
INSERT INTO stats (id, "user", strength, agility, durability, intelligence, wisdom, charisma) VALUES(statId, userId, 3, 3, 3, 3, 3, 3);
END IF;       
SELECT nextval(''weapon_id_seq'') INTO wId; 
INSERT INTO weapon(id, name, level, strength, "user") VALUES (wId, weaponvar, 1, 40, userId);                          
RETURN TRUE;
END;';

-- 3.3.3 - Wysyłanie prywatnych wiadomości

CREATE OR REPLACE FUNCTION sendMessage(sender integer, receiver integer, title text, content text) RETURNS bool LANGUAGE plpgsql AS 'DECLARE   
msgId INTEGER;  
titlevar TEXT;
contentvar TEXT;
BEGIN      
SELECT regexp_replace($3, ''\;|\(\)'', '''', ''g'') INTO titlevar;
SELECT regexp_replace($4, ''\;'', '''', ''g'') INTO contentvar;     

SELECT nextval(''privatemessage_id_seq'') INTO msgId;
INSERT INTO privatemessage(id, sender, receiver, title, content) VALUES(msgId, $1, $2, titlevar, contentvar);
                                          
RETURN TRUE; 
END;  ';

-- 3.3.4 - Dodawanie nowych postów i tematów

CREATE OR REPLACE FUNCTION addPost(topicId integer, userName text, content text, defence bool, attack integer) RETURNS bool LANGUAGE plpgsql AS '
DECLARE
userId integer;
err integer;
postId integer;
resultstr text;
BEGIN
SELECT * FROM selectID($2) INTO userId;
SELECT nextval(''post_id_seq'') INTO postId;

IF $5 = 0 THEN
INSERT INTO post (id, topic, "user", content, defence, result, attack, publish_date) VALUES(postId, $1, userId, regexp_replace($3, ''\;'', '''', ''g''), $4, '''', NULL, CURRENT_TIMESTAMP);
ELSE
SELECT result FROM result(userId, $5, $4) INTO resultstr;
INSERT INTO post (id, topic, "user", content, defence, result, attack, publish_date) VALUES(postId, $1, userId, regexp_replace($3, ''\;'', '''', ''g''), $4, resultstr, $5, CURRENT_TIMESTAMP);
END IF;
RETURN TRUE;
END;
';

CREATE FUNCTION change_post_number() RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
forum_id integer;
topic_id integer;
BEGIN  
topic_id := NEW."topic";
SELECT t.forum INTO forum_id FROM "topic" t WHERE t.id = topic_id;
UPDATE forum SET post_number = post_number+1 WHERE id = forum_id; 
RETURN NULL;     
END;    
';

CREATE OR REPLACE FUNCTION addTopic(forumId integer, userName text, content text, name text) RETURNS bool LANGUAGE plpgsql AS '
DECLARE
userId integer;
err integer;
topicId integer;
postId integer;
postIns bool;
BEGIN
SELECT * FROM selectID($2) INTO userId;
SELECT nextval(''topic_id_seq'') INTO topicId;
SELECT nextval(''post_id_seq'') INTO postId;

INSERT INTO topic (id, forum, owner, name) VALUES(topicId, $1, userId, regexp_replace($4, ''\;'', '''', ''g''));
UPDATE forum SET topic_number = (SELECT COUNT(*) FROM topic t WHERE t.forum = $1) WHERE id = $1;
SELECT * FROM addPost(topicId, $2, $3, FALSE, 0) INTO postIns;
RETURN TRUE;
END;
';
CREATE OR REPLACE FUNCTION deletePost(postId integer) RETURNS void AS '
DELETE FROM post WHERE id = $1;
'LANGUAGE SQL;

-- 3.3.5 - Walka między użytkownikami

CREATE OR REPLACE FUNCTION result(u1Id integer, u2Id integer, defence bool) RETURNS text LANGUAGE plpgsql AS '
DECLARE
user1roll integer;
user2roll integer;
user1statpower integer;
user2statpower integer;
u1power integer;
u2power integer;
retstr text;
u1health integer;
u2health integer;
wasSuccessfull bool;
u1weapon INTEGER;
u2weapon INTEGER;
BEGIN
wasSuccessfull := false;
SELECT trunc(random() * (6-1) + 1) INTO user1roll;
SELECT trunc(random() * (6-1) + 1) INTO user2roll;

SELECT u.health FROM "user" u INTO u1health WHERE u.id = u1Id;
SELECT u.health FROM "user" u INTO u2health WHERE u.id = u2Id;

SELECT w.strength INTO u1weapon FROM weapon w WHERE w."user" = u1Id;
SELECT w.strength INTO u2weapon FROM weapon w WHERE w."user" = u2Id;

SELECT (s.strength + s.agility + s.durability + s.intelligence + s.wisdom + s.charisma)*user1roll FROM stats s INTO user1statpower WHERE s."user" = u1Id; 
SELECT (s.strength + s.agility + s.durability + s.intelligence + s.wisdom + s.charisma)*user2roll FROM stats s INTO user2statpower WHERE s."user" = u2Id;

SELECT w.level * 10 + w.strength + user1statpower FROM weapon w INTO u1power WHERE w."user" = u1Id;
SELECT w.level * 10 + w.strength + user2statpower FROM weapon w INTO u2power WHERE w."user" = u2Id;

IF defence THEN
SELECT cast(cast(random() as integer) as boolean) INTO wasSuccessfull;
END IF;

IF u1power > u2power THEN
	retstr := ''Wygrywasz mocą '' || u1power || '' z przeciwnikiem o mocy '' || u2power || ''. Przeciwnik traci '' || trunc((u1power-u2power)/10) || '' życia.'';
	UPDATE "user" SET health = u2health-trunc((u1power-u2power)/10) WHERE id = u2id;
	UPDATE weapon SET strength = u1weapon + 25 WHERE weapon."user" = u1Id;
	UPDATE weapon SET strength = u2weapon + 10 WHERE weapon."user" = u2Id;
ELSE
	IF wasSuccessfull THEN 
		retstr := ''Przegrywasz mocą '' || u1power || '' z przeciwnikiem o mocy '' || u2power || ''. Udało ci się obronić, ale tracisz '' || trunc((u2power-u1power)/100) || '' życia.'';
		UPDATE "user" SET health = u1health-trunc((u2power-u1power)/100) WHERE id = u1id;
		UPDATE weapon SET strength = u2weapon + 40 WHERE w."user" = u2Id;
	ELSE
		retstr := ''Przegrywasz mocą '' || u1power || '' z przeciwnikiem o mocy '' || u2power || ''. Tracisz '' || trunc((u2power-u1power)/10) || '' życia.'';
		UPDATE "user" SET health = u1health-trunc((u2power-u1power)/10) WHERE id = u1id;
		UPDATE weapon SET strength = u1weapon + 10 WHERE w."user" = u1Id;
		UPDATE weapon SET strength = u2weapon + 40 WHERE w."user" = u2Id;
	END IF;
END IF;
RETURN retstr;
END;
';

-- 3.3.6 - Funkcje moderatorów

CREATE OR REPLACE FUNCTION change_post_number_when_delete() RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
postCount integer;
forum_id integer;
topic_id integer;
BEGIN  
topic_id := OLD."id";
SELECT COUNT(*) FROM post INTO postCount WHERE topic = topic_id;
SELECT t.forum INTO forum_id FROM "topic" t WHERE t.id = topic_id;
UPDATE forum SET post_number = post_number-postCount WHERE id = forum_id; 
RETURN NULL;     
END;    
';

CREATE OR REPLACE FUNCTION change_post_number_when_delete_one() RETURNS trigger LANGUAGE plpgsql AS '
DECLARE
forum_id integer;
topic_id integer;
BEGIN  
topic_id := OLD."topic";
SELECT t.forum INTO forum_id FROM "topic" t WHERE t.id = topic_id;
UPDATE forum SET post_number = post_number-1 WHERE id = forum_id; 
RETURN NULL;     
END;    
';

CREATE OR REPLACE FUNCTION deleteTopic(topicId integer) RETURNS void AS '
DELETE FROM post WHERE topic = $1;
DELETE FROM topic WHERE id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION deleteUser(userId integer) RETURNS void AS '
DELETE FROM post WHERE "user" = $1;
DELETE FROM topic WHERE owner = $1;
DELETE FROM stats WHERE "user" = $1;
DELETE FROM weapon WHERE "user" = $1;
DELETE FROM privatemessage WHERE sender = $1 OR receiver = $1;
DELETE FROM "user" WHERE id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION banUser(userId integer) RETURNS void AS '
UPDATE "user" SET blacklist=1, permission_level = 1 WHERE id = $1;
'LANGUAGE SQL;

CREATE OR REPLACE FUNCTION unbanUser(userId integer) RETURNS void AS '
UPDATE "user" SET blacklist=NULL, permission_level = 2 WHERE id = $1;
'LANGUAGE SQL;

