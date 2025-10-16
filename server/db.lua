local QBCore = exports["qb-core"]:GetCoreObject()

local DB = {}

--- Ensure DB tables exist (jobs + points)
function DB.ensureSchema()
    -- jobs table
    MySQL.query([[CREATE TABLE IF NOT EXISTS `jk_jobs` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(50) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `name_UNIQUE` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])

    -- job points table
    MySQL.query([[CREATE TABLE IF NOT EXISTS `jk_job_points` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `uuid` CHAR(36) NOT NULL UNIQUE DEFAULT (UUID()),
        `job_id` INT NOT NULL,
        `type` VARCHAR(25) NOT NULL,
        `coords` LONGTEXT NOT NULL,
        `label` VARCHAR(100) DEFAULT NULL,
        `grade` INT DEFAULT 0,
        `options` LONGTEXT,
        `blip` LONGTEXT,
        `data` LONGTEXT,
        PRIMARY KEY (`id`),
        KEY `fk_job_idx` (`job_id`),
        CONSTRAINT `fk_job` FOREIGN KEY (`job_id`) REFERENCES `jk_jobs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])

    -- ensure uuid column exists for legacy installations
    MySQL.query([[ALTER TABLE `jk_job_points` ADD COLUMN IF NOT EXISTS `uuid` CHAR(36) NOT NULL UNIQUE DEFAULT (UUID())]])
end

--- Convert SQL rows to in-memory config structure resembling old static Config
local function buildConfig(jobsRows, pointsRows)
    local cfg = { jobs = {} }
    for _, j in ipairs(jobsRows) do
        cfg.jobs[j.name] = {}
    end
    for _, p in ipairs(pointsRows) do
        -- fetch job name via cached map
        local jobName
        for _, j in ipairs(jobsRows) do
            if j.id == p.job_id then
                jobName = j.name
                break
            end
        end
        if jobName then
            local uuid = p.uuid -- keep reference for admin operations
            local coordsVec = (function(c) local t=json.decode(c); return vector3(t.x, t.y, t.z) end)(p.coords)
            local dataPayload = nil
            if p.data then
                local ok, decoded = pcall(json.decode, p.data)
                if ok then dataPayload = decoded end
            end
            if p.type == 'shop' then

                local opts = p.options and json.decode(p.options) or {}
               if opts.requireJob == false or opts.requireJob == "false" or opts.requireJob == 0 then
                opts.requireJob = false
               else
                opts.requireJob = true
               end

                cfg.jobs[jobName][p.type] = {
                    name = p.label or (jobName .. ' Shop'),
                    inventory = opts.inventory or {},
                    locations = { coordsVec },
                    grades = opts.grades or { [jobName] = p.grade or 0 },
                    data = opts.data or {},
                    blip = p.blip and json.decode(p.blip) or nil,
                    requireJob = opts.requireJob
                }
                cfg.jobs[jobName][p.type].job = opts.job or { [jobName] = p.grade or 0 }
                cfg.jobs[jobName][p.type].uuid = uuid
            elseif p.type == 'garage' then
                local opts = p.options and json.decode(p.options) or {}
                cfg.jobs[jobName][p.type] = {
                    coords = coordsVec,
                    returnCoords = opts.returnCoords and vector3(opts.returnCoords.x, opts.returnCoords.y, opts.returnCoords.z) or vector3(coordsVec.x, coordsVec.y + 2.0, coordsVec.z),
                    deleteCoords = opts.deleteCoords and vector3(opts.deleteCoords.x, opts.deleteCoords.y, opts.deleteCoords.z) or vector3(coordsVec.x, coordsVec.y + 4.0, coordsVec.z),
                    spawnCoords = opts.spawnCoords and vector4(opts.spawnCoords.x, opts.spawnCoords.y, opts.spawnCoords.z, opts.spawnCoords.w or 0.0) or vector4(coordsVec.x, coordsVec.y, coordsVec.z, 0.0),
                    options = opts.options or {},
                    title = p.label or (jobName .. ' Garage'),
                    livery = opts.livery or false,
                    blip = p.blip and json.decode(p.blip) or nil,
                    data = opts.data or {},
                }
                cfg.jobs[jobName][p.type].job = opts.job or { [jobName] = p.grade or 0 }
                cfg.jobs[jobName][p.type].uuid = uuid
            else
                local opts = p.options and json.decode(p.options) or {}
                cfg.jobs[jobName][p.type] = {
                    coords = coordsVec,
                    label = p.label,
                    grade = p.grade,
                    slots = opts.slots,
                    weight = opts.weight,
                    data = dataPayload or opts.data or {},
                    blip = p.blip and json.decode(p.blip) or nil,
                }
                cfg.jobs[jobName][p.type].job = opts.job or { [jobName] = p.grade or 0 }
                cfg.jobs[jobName][p.type].uuid = uuid
                if p.type == 'cloth' then
                    cfg.jobs[jobName][p.type].event = dataPayload
                    if type(cfg.jobs[jobName][p.type].data) ~= 'table' then
                        cfg.jobs[jobName][p.type].data = {}
                    end
                end
            end
        end
    end
    return cfg
end

--- Public: load full config from DB
function DB.loadConfig()
    local jobsRows = MySQL.query.await("SELECT * FROM jk_jobs") or {}
    local pointsRows = MySQL.query.await("SELECT * FROM jk_job_points") or {}
    return buildConfig(jobsRows, pointsRows)
end

--- Internal helper: ensure job exists and return id
local function getOrCreateJobId(jobName)
    local row = MySQL.query.await('SELECT id FROM jk_jobs WHERE name = ?', { jobName })
    if row and row[1] then return row[1].id end
    local insert = MySQL.query.await('INSERT INTO jk_jobs(name) VALUES (?)', { jobName })
    return insert.insertId
end

--- Public: add point (data table fields: job, type, coords, label, grade, options, blip, data)
function DB.addPoint(data)
    local jobId = getOrCreateJobId(data.job)
    MySQL.query.await('INSERT INTO jk_job_points(job_id, type, coords, label, grade, options, blip, data) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        jobId,
        data.type,
        json.encode(data.coords),
        data.label or nil,
        data.grade or 0,
        data.options and json.encode(data.options) or nil,
        data.blip and json.encode(data.blip) or nil,
        data.data and json.encode(data.data) or nil,
    })
end

--- Public: delete point by uuid
function DB.deletePoint(uuid)
    MySQL.query.await('DELETE FROM jk_job_points WHERE uuid = ?', { uuid })
end

--- Public: update point by uuid
function DB.updatePoint(uuid, fields)
    local sets = {}
    local params = {}
    for k, v in pairs(fields) do
        table.insert(sets, ("`%s` = ?"):format(k))
        if k == 'coords' or k == 'options' or k == 'blip' or k == 'data' then
            table.insert(params, json.encode(v))
        else
            table.insert(params, v)
        end
    end
    local sql = 'UPDATE jk_job_points SET ' .. table.concat(sets, ', ') .. ' WHERE uuid = ?'
    table.insert(params, uuid)
    MySQL.query.await(sql, params)
end

--- Public: permission check for admin role
function DB.isAdmin(src)
    return QBCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')
end

--- Public: return all points with job name for admin menus
function DB.getAllPoints()
    local rows = MySQL.query.await([[SELECT p.uuid, j.name as job, p.type, p.label, p.grade, p.coords FROM jk_job_points p INNER JOIN jk_jobs j ON j.id = p.job_id]]) or {}
    -- Convert coords JSON to table for client convenience
    for _, r in ipairs(rows) do
        r.coords = json.decode(r.coords)
    end
    return rows
end

function DB.clonePoint(uuid, overrides)
    overrides = overrides or {}
    local rows = MySQL.query.await('SELECT * FROM jk_job_points WHERE uuid = ?', { uuid }) or {}
    local source = rows[1]
    if not source then return false end

    local coordsJson = source.coords
    if overrides.coords then
        coordsJson = json.encode(overrides.coords)
    end

    local label = overrides.label
    if label == '' then label = nil end
    if label == nil then label = source.label end

    local grade = overrides.grade
    if grade == nil then
        grade = source.grade
    end

    local insert = MySQL.query.await('INSERT INTO jk_job_points(job_id, type, coords, label, grade, options, blip, data) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        source.job_id,
        source.type,
        coordsJson,
        label,
        grade,
        source.options,
        source.blip,
        source.data,
    })

    if not insert then return false end
    if insert.affectedRows and insert.affectedRows > 0 then return true end
    if insert.insertId then return true end
    return true
end

return DB
