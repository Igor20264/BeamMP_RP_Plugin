local sql = "SELECT users.id, users.player_name, users_groups.group_id, cmd_permissions.cmd FROM users INNER JOIN users_groups ON users.id = users_groups.user_id INNER JOIN cmd_permissions ON (entity = 'group' AND entity_id = users_groups.group_id) OR (entity = 'user' AND entity_id = users.id) WHERE users.player_name = '%s' AND cmd_permissions.cmd = '%s'";
local dbRes = MYSQL.execute("read", sql, {nick, cmd})
local access = MYSQL.fetchAll(dbRes)
if #access > 0 then
    return true;
end
return false;