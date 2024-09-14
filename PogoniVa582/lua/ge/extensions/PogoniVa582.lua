-- Приватный мод для погонь. Версия №2. Версия №3 пока в разработке.
-- Автор VA582. Почта va582@ya.ru. Дискорд melkiy582#8370.
-- Вся логика вынесена на сторону сервера.
-- Последнее изменение 2022/08/21.

local M = {};

local logTag = "PogoniVa582";
-- Локальные переменные

local NulevajaPozicija = vec3(0, 0, 0);
local VesTransport = {}; -- Слепок MPVehicleGE.getVehicles();
local MojTransport = {}; --[[
MojTransport = {
	["IdTransporta"] = {
		["IdTransportaServer"] = ,
		["TochkaRemonta"] = NulevajaPozicija
		["PosledneeVremjaRemonta"] = 0
	}
}

]]--

local VidimyjTransport = {}; --[[
VidimyjTransport = {
	IdTransporta = {
		IdTransporta = { тип строка!
			Komanda
			Cvet = {
				CvetK
				CvetZ
				CvetS
				CvetP
			}
		}
	}
}
]]--
local VidimyjTransportServer = {}; --[[
VidimyjTransport = {
	IdTransporta = {
		IdTransporta = { тип строка!
			Komanda
			Cvet = {
				CvetK
				CvetZ
				CvetS
				CvetP
			}
		}
	}
}
]]--
local VidimyeIgroki = {};
--    ДанныеДляИнтерфейса, храним в переменной на случай если выберем другой и вернём обратно
local DannyeDljaInterfejsa = {
	["KomandyIgrokov"] = {
		["Grazhdanskih"] = "0",
		["Policeiskih"] = "0",
		["Podozrevaemyh"] = "0",
		["PoliceiskieStrokoj"] = "нет игроков",
		["PodozrevaemyeStrokoj"] = "нет игроков",
		["KomandaIgroka"] = "без команды",
		["ImjaIgroka"] = "guest0123456",
		["PoUmolchaniju"] = true
	},
	["Vremja"] = {
		["VremjaOstalosVidno"] = false,
		["VremjaOstalos"] = "00:00",
		["VremjaDopVidno"] = false,
		["VremjaDop"] = "00:00"
	},
	["Status"] = {
		["StatusPogoni"] = "ожидание игроков"
	},
	["SmenaKomand"] = {
		["Vidno"] = true
	}
};
local CvetaKomand = {};
local TochkiRemonta = {};

local StatusPogoni = {};
local Ogranichenija = {};

local IdyTransportaNaDobavlenie = {};
local IdyTransportaNaYdalenie = {};
--local MirGotov = false;
local SummaDt = 0;





-- Вспомогательные функции

local function ObjektVJSON(Objekt)
	local Stroka = jsonEncode(Objekt);
	-- Двоеточие ":" нельзя передавать между клиентом и сервером.
	local StrokaSZamenoj = string.gsub(Stroka, ":", "=Dvoetochie=");
	return StrokaSZamenoj;
end;

local function JSONVObjekt(Stroka)
	-- Двоеточие ":" нельзя передавать между клиентом и сервером.
	local StrokaSZamenoj = string.gsub(Stroka, "=Dvoetochie=", ":");
	local Objekt = jsonDecode(StrokaSZamenoj);
	return Objekt;
end; 




-- Основные функции

local function VypolnitjDejstvie(OpisanieDejstvija)
	local KolichestvoArgumentov = #OpisanieDejstvija.Argumenty;
	local Procedura = extensions[OpisanieDejstvija.Rasshirenie][OpisanieDejstvija.Dejstvie];
	if KolichestvoArgumentov == 1 then
		Procedura(OpisanieDejstvija.Argumenty[1]);
	elseif KolichestvoArgumentov == 2 then
		Procedura(OpisanieDejstvija.Argumenty[1], OpisanieDejstvija.Argumenty[2]);
	elseif KolichestvoArgumentov == 3 then
		Procedura(OpisanieDejstvija.Argumenty[1], OpisanieDejstvija.Argumenty[2], OpisanieDejstvija.Argumenty[3]);
	end;
end;

local function ObnovitOgranichenijaObschee(Spisok)
	if Spisok == nil then return; end;
	local MassivPozicij = {};
	for Pozicija, _ in pairs (Spisok) do
		--log('D', 'PogoniVa582.ObnovitOgranichenijaObschee()', "Pozicija = "..tostring(Pozicija))
		table.insert(MassivPozicij, Pozicija);
	end;
	table.sort(MassivPozicij);
	for _, Pozicija in pairs (MassivPozicij) do
		--log('D', 'PogoniVa582.ObnovitOgranichenijaObschee()', "Pozicija = "..tostring(Pozicija))
		local OpisanieDejstvija = Spisok[Pozicija];
		VypolnitjDejstvie(OpisanieDejstvija);
	end;
end;

local function ObnovitOgranichenija(TolkoPostojannye)
	if Ogranichenija ~= nil then
		TolkoPostojannye = TolkoPostojannye or false;
		ObnovitOgranichenijaObschee(Ogranichenija["Postojannye"]);
		if not TolkoPostojannye then
			ObnovitOgranichenijaObschee(Ogranichenija["Vremennye"]);
		end;
	end;
end;

local function ObnovitVesTransport()
	VesTransport = MPVehicleGE.getVehicles();
	MojTransport = {};
	VidimyjTransport = {};
	
	for IdTranspKomb, IdTranspKombInfo in pairs(VesTransport) do
		if IdTranspKombInfo.isLocal then
			MojTransport[IdTranspKombInfo.gameVehicleID] = {
				["IdTransportaServer"] = IdTranspKombInfo.serverVehicleID, 
				["TochkaRemonta"] = NulevajaPozicija
			};
		end;
	end;
	
	for IdTranspKomb, IdyTranspKombDrug in pairs(VidimyjTransportServer) do
		if VesTransport[IdTranspKomb] == nil then
			goto Prodolzhitj;
		end;
		local IdTransp = -1;
		if IdTranspKomb ~= "-1" then
			IdTransp = VesTransport[IdTranspKomb].gameVehicleID;
		end;
		VidimyjTransport[IdTransp] = {};
		for IdTranspKombDrug, Komanda in pairs(IdyTranspKombDrug) do
			if VesTransport[IdTranspKombDrug] == nil then
				goto Prodolzhitj;
			end;
			VidimyjTransport[IdTransp][VesTransport[IdTranspKombDrug].gameVehicleID] = Komanda;
		end;
		::Prodolzhitj::
	end;
	
end;

local function ProveritTransportDobavlen()

	local TablicaKOtpravke = {};
	local KolvoDo = #IdyTransportaNaDobavlenie;
	log('D', 'ProveritTransportDobavlen()', "1");
	for _, TekuschiiTransport in pairs(MPVehicleGE.getVehicles()) do
		for Index, IdTransportaNaDobavlenie in pairs(IdyTransportaNaDobavlenie) do
			--log('D', 'ProveritTransportDobavlen()', "TekuschiiTransport.gameVehicleID ~= IdTransportaNaDobavlenie");
			--log('D', 'ProveritTransportDobavlen()', tostring(TekuschiiTransport.gameVehicleID) .. " ~= ");
			if TekuschiiTransport.gameVehicleID ~= IdTransportaNaDobavlenie then
				goto Prodolzhitj;
			end;
			if not TekuschiiTransport.isLocal then
				TablicaKOtpravke[TekuschiiTransport.serverVehicleString] = {
					["ownerID"] = TekuschiiTransport.ownerID,
					["serverVehicleID"] = TekuschiiTransport.serverVehicleID,
					["gameVehicleID"] = TekuschiiTransport.gameVehicleID
				};
			end;
			table.remove(IdyTransportaNaDobavlenie, Index);
			::Prodolzhitj::;
		end;
	end;
	log('D', 'ProveritTransportDobavlen()', "2");
	if TablicaKOtpravke ~= {} then
		local InfoStrokoj = ObjektVJSON(TablicaKOtpravke);
		log('D', 'ProveritTransportDobavlen()', "TablicaKOtpravke");
		log('D', 'ProveritTransportDobavlen()', dump(TablicaKOtpravke));
		TriggerServerEvent("ObrabotchikPoluchenijaIdTransportaSIgrokov", InfoStrokoj);
	end;
	log('D', 'ProveritTransportDobavlen()', "3");
	if #IdyTransportaNaDobavlenie ~= KolvoDo then
		ObnovitVesTransport();
	end;
	
end;

local function ProveritTransportYdalen()
	for IdTransportaNaYdalenie, _ in pairs(IdyTransportaNaYdalenie) do
		local IdNeNajden = true;
		for _, TekuschiiTransport in pairs(MPVehicleGE.getVehicles()) do
			if TekuschiiTransport.gameVehicleID == IdTransportaNaYdalenie then
				IdNeNajden = false;
			end;
		end;
		if IdNeNajden then
			IdyTransportaNaYdalenie[IdTransportaNaYdalenie] = nil;
		end;
	end;
	ObnovitVesTransport();
end;




-- Процедуры, для обновления элементов интерфейса

local function ObnovitjInterfejs(ChastjDannyhDljaInterfejsa)
	local ImenaBlokov = {};
	if ChastjDannyhDljaInterfejsa ~= nil then
		for ImjaBloka, ParametryBloka in pairs(ChastjDannyhDljaInterfejsa) do
			table.insert(ImenaBlokov, ImjaBloka);
			DannyeDljaInterfejsa[ImjaBloka] = ParametryBloka;
		end;
	end;
	for ImjaBloka, ParametryBloka in pairs(DannyeDljaInterfejsa) do
		--log('D', '3ObnovitjInterfejs()', "1guihooks.trigger(\"ustanovit\"..ImjaBloka, ParametryBloka) = ");
		if #ImenaBlokov > 0 then
			for Sch = 1, #ImenaBlokov + 1 do
				if ImjaBloka == ImenaBlokov[Sch] then
					--log('D', '4ObnovitjInterfejs()', "1guihooks.trigger(\"ustanovit\"..ImjaBloka, ParametryBloka) = ");
					--log('D', '4ObnovitjInterfejs()', tostring(ImjaBloka));
					--log('D', '4ObnovitjInterfejs()', dump(ParametryBloka));
					guihooks.trigger("ustanovit"..ImjaBloka, ParametryBloka);
				end;
			end;
		else
			--log('D', '5ObnovitjInterfejs()', "3guihooks.trigger(\"ustanovit\"..ImjaBloka, ParametryBloka) = ");
			guihooks.trigger("ustanovit"..ImjaBloka, ParametryBloka);
		end;
	end;
	
end;

local function ObnovitjInterfejsPoUmolchaniju()
	if DannyeDljaInterfejsa.KomandyIgrokov.PoUmolchaniju then
		DannyeDljaOtpravkiJSON = ObjektVJSON("Civil");
		TriggerServerEvent("ObrabotchikZaprosaSmenyKomandy", DannyeDljaOtpravkiJSON);
	end;
	ObnovitjInterfejs();
end;




-- Отдельные запросы на сервер, обработчики нажатия кнопок на интерфейсе

--    Функция  ЗапросСменыКоманды(ЖелаемаяКоманда)
local function ZaprosSmenyKomandy(ZhelaemajaKomanda)
	--log('D', 'ZaprosSmenyKomandy(ZhelaemajaKomanda)', "ZhelaemajaKomanda = " .. tostring(ZhelaemajaKomanda));
	local DannyeDljaOtpravki = {};
	local KolichestvoTransporta = 0;
	for _, _ in pairs(MojTransport) do
		KolichestvoTransporta = KolichestvoTransporta + 1;
	end;
	--log('D', 'ZaprosSmenyKomandy(ZhelaemajaKomanda)', "KolichestvoTransporta = " .. tostring(KolichestvoTransporta));
	if KolichestvoTransporta == 0 or KolichestvoTransporta == 1 then
		DannyeDljaOtpravki = ZhelaemajaKomanda;
	elseif KolichestvoTransporta >= 2 then
		local TekuschiiTransportObjekt = be:getPlayerVehicle(0);
		if TekuschiiTransportObjekt ~= nil then
			local IdTransporta = be:getPlayerVehicle(0):getID();
			if MPVehicleGE.isOwn(IdTransporta) then
				DannyeDljaOtpravki = {IdTransporta, ZhelaemajaKomanda};
			else
				DannyeDljaOtpravki = ZhelaemajaKomanda;
			end;
		else
			DannyeDljaOtpravki = ZhelaemajaKomanda;
		end;
	end;
	local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
	--log('D', 'ZaprosSmenyKomandy(ZhelaemajaKomanda)', "DannyeDljaOtpravkiJSON = " .. tostring(DannyeDljaOtpravkiJSON));
	TriggerServerEvent("ObrabotchikZaprosaSmenyKomandy", DannyeDljaOtpravkiJSON);
end;

local function ZaprosZapuskaPogoni(IgrovojRezhim)
	local DannyeDljaOtpravkiJSON = ObjektVJSON(IgrovojRezhim);
	TriggerServerEvent("ObrabotchikZaprosaGolosovanija", DannyeDljaOtpravkiJSON);
end;

local function PodgotovkaZaprosGotovnostj()
	local DannyeDljaOtpravkiJSON = ObjektVJSON(true);
	TriggerServerEvent("ObrabotchikPodgotovkaZaprosGotovnostj", DannyeDljaOtpravkiJSON);
end;

local function PodgotovkaZaprosUstanovitjTochkuRemonta()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local DannyeDljaOtpravki = {
			["IdTransportaServer"] = MPVehicleGE.getVehicleByGameID(SvojTekuschiiTransport:getID()).serverVehicleID,
			["Pozicija"] = SvojTekuschiiTransport:getPosition()
		};
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPodgotovkaZaprosUstTochkuRemonta", DannyeDljaOtpravkiJSON);
	end;
end;

local function PogonjaZaprosRemont()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		--local PosledneeVremjaRemonta = MPVehicleGE.getVehicleByGameID(IdTransporta).lastDt; -- пустое
		local PosledneeVremjaRemonta = math.random(1, 1000);
		local DannyeDljaOtpravki = {
			["IdTransporta"] = IdTransporta,
			["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		};
		MojTransport[IdTransporta]["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPogonjaZaprosRemont", DannyeDljaOtpravkiJSON);
	end;
end;

local function PogonjaOtremontirovatj(ParametryStrokoi)
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local Parametry = JSONVObjekt(ParametryStrokoi);
		log('D', 'PogonjaOtremontirovatj()', "IdTransporta = " .. tostring(IdTransporta));
		log('D', 'PogonjaOtremontirovatj()', dump(Parametry));
		log('D', 'PogonjaOtremontirovatj()', dump(MojTransport));
		if Parametry.IdTransporta == IdTransporta and MojTransport[IdTransporta].PosledneeVremjaRemonta == Parametry.PosledneeVremjaRemonta then
			log('D', 'PogonjaOtremontirovatj()', "Vyp");
			spawn.safeTeleport(SvojTekuschiiTransport, vec3(Parametry.Pozicija), quat(Parametry.VraschenieQuat), true);
			--MPVehicleGE.sendVehicleEdit(IdTransporta);
		end;
	end;
end;

local function PogonjaZaprosVyjti()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local DannyeDljaOtpravki = {
			["IdTransporta"] = IdTransporta
		};
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPogonjaZaprosVyjti", DannyeDljaOtpravkiJSON);
	end;
end;


-- переписать компактнее
local function PogonjaZaprosNachatjRemont()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local PosledneeVremjaRemonta = math.random(1, 1000);
		local DannyeDljaOtpravki = {
			["IdTransporta"] = IdTransporta,
			["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		};
		MojTransport[IdTransporta]["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPogonjaZaprosNachatjRemont", DannyeDljaOtpravkiJSON);
	end;
end;

local function PogonjaZaprosOtkatNaSpavn()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local PosledneeVremjaRemonta = math.random(1, 1000);
		local DannyeDljaOtpravki = {
			["IdTransporta"] = IdTransporta,
			["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		};
		MojTransport[IdTransporta]["PosledneeVremjaRemonta"] = PosledneeVremjaRemonta;
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPogonjaZaprosOtkatNaSpavn", DannyeDljaOtpravkiJSON);
	end;
end;

local function PogonjaZaprosPrervatjRemont()
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local DannyeDljaOtpravki = {
			["IdTransporta"] = IdTransporta
		};
		local DannyeDljaOtpravkiJSON = ObjektVJSON(DannyeDljaOtpravki);
		TriggerServerEvent("ObrabotchikPogonjaZaprosPrervatjRemont", DannyeDljaOtpravkiJSON);
	end;
end;

local function PogonjaZavershitjRemont(ParametryStrokoj)
	local SvojTekuschiiTransport = be:getPlayerVehicle(0);
	if SvojTekuschiiTransport then
		local IdTransporta = SvojTekuschiiTransport:getID();
		local Parametry = JSONVObjekt(ParametryStrokoj);
		log('D', 'PogonjaZavershitjRemont()', "IdTransporta = " .. tostring(IdTransporta));
		log('D', 'PogonjaZavershitjRemont()', "type(IdTransporta) = " .. tostring(type(IdTransporta)));
		log('D', 'PogonjaZavershitjRemont()', "Parametry.IdTransporta = " .. tostring(Parametry.IdTransporta));
		log('D', 'PogonjaZavershitjRemont()', "MojTransport[IdTransporta].PosledneeVremjaRemonta = " .. tostring(MojTransport[IdTransporta].PosledneeVremjaRemonta));
		log('D', 'PogonjaZavershitjRemont()', "Parametry.PosledneeVremjaRemonta = " .. tostring(Parametry.PosledneeVremjaRemonta));
		log('D', 'PogonjaZavershitjRemont()', dump(MojTransport));
		--if Parametry.IdTransporta == IdTransporta and MojTransport[IdTransporta].PosledneeVremjaRemonta == Parametry.PosledneeVremjaRemonta then
		if Parametry.IdTransporta == IdTransporta then
			spawn.safeTeleport(SvojTekuschiiTransport, vec3(Parametry.Pozicija), quat(Parametry.VraschenieQuat));
			-- Найти функцию, как при нажатии Insert
		end;
	end;
end;


local function VypolnitjDejstvieSTransportom(ParametryStrokoj)
	local Parametry = JSONVObjekt(ParametryStrokoj);
	--log('D', 'VypolnitjDejstvieSTransportom(ParametryStrokoj)', dump(Parametry));
	Parametry.Argumenty[1] = be:getObjectByID(Parametry.Argumenty[1]);
	VypolnitjDejstvie(Parametry);
end;

local function SmenaKnopkiRemonta(ParametryStrokoj)
	local Parametry = JSONVObjekt(ParametryStrokoj);
	
end;


-- Процедуры, вызываемые добавленными обрботчиками событий, при получении команды с сервера

--    Функция  ОбновлениеОграничений(ОграниченияСтрокой)
local function ObnovlenieOgranichenij(OgranichenijaStrokoj)
	Ogranichenija = JSONVObjekt(OgranichenijaStrokoj);
	--log('D', 'ObnovlenieOgranichenij()', "OgranichenijaStrokoj = " .. tostring(OgranichenijaStrokoj));
	--log('D', 'ObnovlenieOgranichenij()', "Ogranichenija = " .. tostring(Ogranichenija));
	ObnovitOgranichenija();
end;

--    Функция  ОбновлениеИнтерфейса(ДанныеДляИнтерфейсаСтрокой)
local function ObnovlenieInterfejsa(DannyeDljaInterfejsaStrokoj)
	--log('D', 'ObnovlenieInterfejsa()', "DannyeDljaInterfejsaStrokoj = " .. tostring(DannyeDljaInterfejsaStrokoj));
	local DannyeDljaInterfejsa_ = JSONVObjekt(DannyeDljaInterfejsaStrokoj);
	ObnovitjInterfejs(DannyeDljaInterfejsa_);
end;

local function ObnovlenieOkruzhenija(ParametryStrokoi)
	
	local Parametry = JSONVObjekt(ParametryStrokoi);
	
	
	
end;

--    Функция  ОбновленияОперативнойИнфыПоТранспорту(ПараметрыСтрокой)
local function ObnovlenieOperativnojInfyPoTransportu(ParametryStrokoi)
	
	local Parametry = JSONVObjekt(ParametryStrokoi);
	local InfoVsegoTransporta = {};
	for IdTransporta, IdTransportaInfo in pairs(MojTransport) do 
		local InfoTransporta = map.objects[IdTransporta];
		InfoVsegoTransporta[IdTransportaInfo.IdTransportaServer] = {};
		for _, ImjaParametra in pairs(Parametry.ImenaParametrov) do
			InfoVsegoTransporta[IdTransportaInfo.IdTransportaServer][ImjaParametra] = InfoTransporta[ImjaParametra];
		end;
		if InfoTransporta.active then
			InfoVsegoTransporta[IdTransportaInfo.IdTransportaServer]["VraschenieKamery"] = getCamera():getRotation():toTable();
		else
			InfoVsegoTransporta[IdTransportaInfo.IdTransportaServer]["VraschenieKamery"] = quat(0, 0, 0, 0);
		end;
	end;
	local InfoVsegoTransportaJSON = ObjektVJSON(InfoVsegoTransporta);
	TriggerServerEvent("ObrabotchikObnovlenijaOperativnojInfyPoTransportu", InfoVsegoTransportaJSON);
	
end;

-- Уже скорее всего не потребуется
--    Функция  ОбновлениеВидимыхИгроков(ВидимыеИгрокиСтрокой)
local function ObnovlenieVidimyhIgrokov(VidimyeIgrokiStrokoi)
	-- Пример отправляемой строки смотреть на сервере в 'print'
	
	-- Сначала очистить
	VidimyeIgroki = {};
	-- Переназначить
	local stroka = VidimyeIgrokiStrokoi;
	-- Начать парсить по точке с запятой
	local PozitsijaRazdelitelja = string.find(stroka, ";");
	-- Счётчик до 10, на всякий случай, чтобы выйти потом из цикла
	local Schetchik = 1;
	while PozitsijaRazdelitelja ~= nil do
		local Podstroka = string.sub(stroka, 1, PozitsijaRazdelitelja - 1);
		local PozitsijaDvoetochija = string.find(Podstroka, "=");
		local IdDrugogoIgroka = tonumber(string.sub(stroka, 1, PozitsijaDvoetochija - 1));
		if VidimyeIgroki[IdDrugogoIgroka] == nil then
			VidimyeIgroki[IdDrugogoIgroka] = {};
		end;
		-- Для первого прохода цикла позиция первой запятой - это точка с запятой
		local PozitsijaPervoiZapjatoi = PozitsijaDvoetochija;
		-- Начать парсить по запятой
		local PozitsijaVtoroiZapjatoi = string.find(Podstroka, ",");
		-- Счётчик до пяти
		local Schetchik2 = 1;
		-- Где каждое значение между запятыми разбираем и присваиваем куда надо
		while Schetchik2 <= 5 do
			local Znachenie = string.sub(Podstroka, PozitsijaPervoiZapjatoi + 1, PozitsijaVtoroiZapjatoi - 1);
			if Schetchik2 == 1 then
				VidimyeIgroki[IdDrugogoIgroka].Komanda = Znachenie;
			elseif Schetchik2 == 2 then
				VidimyeIgroki[IdDrugogoIgroka].CvetK = tonumber(Znachenie);
			elseif Schetchik2 == 3 then
				VidimyeIgroki[IdDrugogoIgroka].CvetZ = tonumber(Znachenie);
			elseif Schetchik2 == 4 then
				VidimyeIgroki[IdDrugogoIgroka].CvetS = tonumber(Znachenie);
			elseif Schetchik2 == 5 then
				VidimyeIgroki[IdDrugogoIgroka].CvetP = tonumber(Znachenie);
			end; 
			Schetchik2 = Schetchik2 + 1;
			local Raznica = PozitsijaVtoroiZapjatoi - PozitsijaPervoiZapjatoi;
			PozitsijaPervoiZapjatoi = PozitsijaVtoroiZapjatoi;
			PozitsijaVtoroiZapjatoi = string.find(Podstroka, ",", PozitsijaVtoroiZapjatoi + 1);
			if PozitsijaVtoroiZapjatoi == nil then PozitsijaVtoroiZapjatoi = string.len(Podstroka) + 1; end;
		end;
		stroka = string.sub(stroka, PozitsijaRazdelitelja + 1, string.len(stroka)) 
		PozitsijaRazdelitelja = string.find(stroka, ";");
		Schetchik = Schetchik + 1;
		if Schetchik > 10 then break; end;
	end;
	
	
	
end

--    Функция  
local function ObnovlenieCvetovKomand(StrokaCvetaKomand)
	CvetaKomand = JSONVObjekt(StrokaCvetaKomand);
end;

--    Функция  
local function ObnovlenieTochekRemonta(StrokaTochkiRemonta)
	TochkiRemonta = JSONVObjekt(StrokaTochkiRemonta);
	for IdTochkiRemonta, InfoTochkiRemonta in pairs(TochkiRemonta) do
		InfoTochkiRemonta.PozicijaNiz = vec3(InfoTochkiRemonta.PozicijaNiz);
		InfoTochkiRemonta.PozicijaVerh = vec3(InfoTochkiRemonta.PozicijaVerh);
		InfoTochkiRemonta["CvetF"] = ColorF(InfoTochkiRemonta.Cvet[1], InfoTochkiRemonta.Cvet[2], InfoTochkiRemonta.Cvet[3], InfoTochkiRemonta.Cvet[4]);
		InfoTochkiRemonta["CvetI"] = ColorI(InfoTochkiRemonta.Cvet[1]*255, InfoTochkiRemonta.Cvet[2]*255, InfoTochkiRemonta.Cvet[3]*255, InfoTochkiRemonta.Cvet[4]*255);
	end;
end;

--    Функция  ОбновлениеВидимогоТранспорта(СтрокаВидимыйТранспорт)
local function ObnovlenieVidimogoTransporta(StrokaVidimyjTransport)
	-- Нужно из серверных Идов переконвертировать в локальные Иды
	VidimyjTransportServer = JSONVObjekt(StrokaVidimyjTransport);
	ObnovitVesTransport();
end;

local Radiusy = {};

-- Функция для отладки радиусов
local function ObnovlenieSfer(ParametryStrokoi)
	--log('D', 'PogoniVa582.ObnovlenieSfer()', "ParametryStrokoi = "..tostring(ParametryStrokoi))
	local RadiusIzJSON = JSONVObjekt(ParametryStrokoi);
	for ImjaRadiusa, InfoRadiusa in pairs(RadiusIzJSON) do
		if Radiusy[ImjaRadiusa] == nil then
			Radiusy[ImjaRadiusa] = {};
		end;
		Radiusy[ImjaRadiusa]["Tekst"] = InfoRadiusa.Tekst;
		Radiusy[ImjaRadiusa]["Pozicija"] = InfoRadiusa.Pozicija;
		if type(InfoRadiusa.Pozicija) == "string" then
			Radiusy[ImjaRadiusa]["IdTransporta"] = VesTransport[InfoRadiusa.Pozicija].gameVehicleID;
		end;
		Radiusy[ImjaRadiusa]["Dlina"] = InfoRadiusa.Dlina;
		Radiusy[ImjaRadiusa]["Cvet"] = InfoRadiusa.Cvet;
		--log('D', 'PogoniVa582.ObnovlenieSfer()', dump(Radiusy))
	end;
end;

local function OtrisovatjSfery()
	for ImjaRadiusa, InfoRadiusa in pairs(Radiusy) do
		--log('D', 'PogoniVa582.OtrisovatjSfery()', "ImjaRadiusa = "..tostring(ImjaRadiusa))
		if InfoRadiusa.Pozicija == nil or InfoRadiusa.Pozicija == vec3(0, 0, 0) then
			--log('D', 'PogoniVa582.OtrisovatjSfery()', "InfoRadiusa.Pozicija = "..tostring(InfoRadiusa.Pozicija))
			goto Prodolzhitj;
		end;
		
		if InfoRadiusa.Dlina == 0 then
			--log('D', 'PogoniVa582.OtrisovatjSfery()', "InfoRadiusa.Dlina = "..tostring(InfoRadiusa.Dlina))
			goto Prodolzhitj;
		end;
		
		local Pozicija = InfoRadiusa.Pozicija;
		if InfoRadiusa["IdTransporta"] ~= nil then
			Pozicija = be:getObjectByID(InfoRadiusa.IdTransporta):getPosition();
		end;
		
		--log('D', 'PogoniVa582.OtrisovatjSfery()', "debugDrawer")
		debugDrawer:drawSphere(Pozicija, InfoRadiusa.Dlina, ColorF(InfoRadiusa.Cvet[1] / 255, InfoRadiusa.Cvet[2] / 255, InfoRadiusa.Cvet[3] / 255, InfoRadiusa.Cvet[4] / 255));
		debugDrawer:drawTextAdvanced(Pozicija, InfoRadiusa.Tekst, ColorF(1, 1, 1, 0.75), true, false, ColorI(InfoRadiusa.Cvet[1], InfoRadiusa.Cvet[2], InfoRadiusa.Cvet[3], InfoRadiusa.Cvet[4]));
		
		::Prodolzhitj::
	end;
end;



-- На удаление
local function PodgotovkaUstanovitjTochkuRemonta(ParametryStrokoi)
	local Parametry = JSONVObjekt(ParametryStrokoi);
	MojTransport[Parametry.IdTransporta].TochkaRemonta = vec3(Parametry.Pozicija);
end;

local function ProveritjNastrojki()
	if core_settings_settings.getValue("trafficAmount") >= 0 then
		core_settings_settings.setValue('trafficAmount', -1);
	end;
end;

local CvetTeksta = ColorF(1, 1, 1, 0.75);
local function OtrisovatjNadpisiTransporta()
	
	-- Текущее транспортное средство
	local SvojTransport = be:getPlayerVehicle(0);
	local SvojTransportId = "-1";
	
	-- Определяем позицию от которой будем вычислять дистанцию
	local SvojaPozicija = NulevajaPozicija;
	if SvojTransport then
		SvojTransportId = SvojTransport:getID();
		SvojaPozicija = SvojTransport:getPosition();
	else
		SvojaPozicija = getCameraPosition();
	end;
	--log('D', 'PogoniVa582.onPreRender()', "SvojTransportId " .. tostring(SvojTransportId));
	--log('D', 'PogoniVa582.onPreRender()', "SvojaPozicija " .. tostring(SvojaPozicija));
	
	-- Перебираем весь транспорт
	--log('D', 'PogoniVa582.onPreRender()', "VesTransport");
	--log('D', 'PogoniVa582.onPreRender()', dump(VesTransport));
	for _, TekuschiiTransport in pairs(VesTransport) do
		local TekuschiiTransportId = TekuschiiTransport.gameVehicleID;
		--log('D', 'PogoniVa582.onPreRender()', "TekuschiiTransportId "..tostring(TekuschiiTransportId));
		
		if TekuschiiTransportId == SvojTransportId then
			-- Если это свой же транспорт
			if not commands.isFreeCamera() then
				-- И не свободная камера, то пропускаем
				goto PropustitTekuschiiTransport;
			else
				--SvojaPozicija = getCameraPosition();
				-- Лучше не надо
			end;
		end;
		
		-- Если не должны видеть
		--log('D', 'PogoniVa582.onPreRender()', "VidimyjTransport[SvojTransportId]");
		--log('D', 'PogoniVa582.onPreRender()', tostring(VidimyjTransport[SvojTransportId]));
		if VidimyjTransport[SvojTransportId] == nil then
			--log('D', 'PogoniVa582.onPreRender()', "goto PropustitTekuschiiTransport; 1") --
			goto PropustitTekuschiiTransport;
		else
			--log('D', 'PogoniVa582.onPreRender()', "VidimyjTransport[SvojTransportId][TekuschiiTransportId]");
			--log('D', 'PogoniVa582.onPreRender()', tostring(VidimyjTransport[SvojTransportId][TekuschiiTransportId]));
			if VidimyjTransport[SvojTransportId][TekuschiiTransportId] == nil then
				goto PropustitTekuschiiTransport;
				--log('D', 'PogoniVa582.onPreRender()', "goto PropustitTekuschiiTransport; 2") --
			end;
		end;
		
		local Komanda = VidimyjTransport[SvojTransportId][TekuschiiTransportId];
		
		--log('D', 'PogoniVa582.onPreRender()', "7 = "..tostring(7))
		local TekuschiiTransportObjekt = be:getObjectByID(TekuschiiTransportId);
		-- Если не нашли - то пропустить
		if TekuschiiTransportObjekt == nil then
			goto PropustitTekuschiiTransport;
		end;
		
		--log('D', 'PogoniVa582.onPreRender()', "8 = "..tostring(8))
		local PozicijaTekuschegoTransporta = TekuschiiTransportObjekt:getPosition();
		
		-- local EdinicaIzmerenija = "";
		-- local Distancija = SvojaPozicija:distance(PozicijaTekuschegoTransporta);
		-- if Distancija >= 1000 then
			-- Distancija = math.floor((Distancija / 10) + 0.5) / 100;
			-- EdinicaIzmerenija = "км";
		-- else
			-- Distancija = math.floor(Distancija);
			-- EdinicaIzmerenija = "м";
		-- end;
		-- local DistancijaStrokoi = tostring(Distancija) .. EdinicaIzmerenija;
		
		-- local StrokaNadpisi = " " .. 
			-- tostring(Komanda) .. " " .. 
			-- tostring(TekuschiiTransport.ownerName) .. " " .. 
			-- tostring(TekuschiiTransport.serverVehicleString) .. " " .. 
			-- DistancijaStrokoi .. 
		-- " ";
		
		local StrokaNadpisi = tostring(TekuschiiTransport.ownerName);
		
		local CvetZadnika = ColorI(CvetaKomand[Komanda].CvetK, CvetaKomand[Komanda].CvetZ, CvetaKomand[Komanda].CvetS, CvetaKomand[Komanda].CvetP);
		
		-- Если не прогрузилась машина - то отрисовка сферы
		if not TekuschiiTransport.isSpawned then
			debugDrawer:drawSphere(PozicijaTekuschegoTransporta, 3, ColorF(CvetZadnika.r/255, CvetZadnika.g/255, CvetZadnika.b/255, 0.5));
		end;
		
		-- Над крышей
		PozicijaTekuschegoTransporta.z = PozicijaTekuschegoTransporta.z + 1.0;
		
		-- Отрисовка текста над машиной
		debugDrawer:drawTextAdvanced(PozicijaTekuschegoTransporta, StrokaNadpisi, CvetTeksta, true, false, CvetZadnika);
		--log('D', 'PogoniVa582.onPreRender()', "9 = "..tostring(9))
		
		:: PropustitTekuschiiTransport ::
		
	end;
end;

local function OtrisovatjTochkiRemonta()
	--for IdTransporta, InfoTransporta in pairs(MojTransport) do
	--	if InfoTransporta.TochkaRemonta ~= NulevajaPozicija then
	--		local Pozicija = InfoTransporta.TochkaRemonta:toDict();
	--		debugDrawer:drawCylinder(vec3(Pozicija.x, Pozicija.y, Pozicija.z - 2.5), vec3(Pozicija.x, Pozicija.y, Pozicija.z + 2.5), 8, ColorF(0.5, 1, 0.5, 0.15));
	--	end;
	--end;
	
	for IdTochkiRemonta, InfoTochkiRemonta in pairs(TochkiRemonta) do
		debugDrawer:drawCylinder(InfoTochkiRemonta.PozicijaNiz, InfoTochkiRemonta.PozicijaVerh, InfoTochkiRemonta.Radius, InfoTochkiRemonta.CvetF);
		debugDrawer:drawTextAdvanced(InfoTochkiRemonta.PozicijaVerh, InfoTochkiRemonta.Tekst, CvetTeksta, true, false, InfoTochkiRemonta.CvetI);
	end;
end;



-- Процедуры, вызываемые встроенными в игру обрботчиками событий

local function onExtensionLoaded()
	-- Функция выполняется при загрузке этой модификации
	-- 1) добавляет обработчики событий
	
	AddEventHandler("ObrabotchikObnovlenijaOgranichenij", 					ObnovlenieOgranichenij);
	AddEventHandler("ObrabotchikObnovlenijaInterfejsa", 					ObnovlenieInterfejsa);
	--AddEventHandler("ObrabotchikObnovlenijaOkruzhenija", 					ObnovlenieOkruzhenija);
	AddEventHandler("ObrabotchikZaprosaOperativInfyPoTranspNaKliente", 		ObnovlenieOperativnojInfyPoTransportu);
	AddEventHandler("ObrabotchikObnovlenijaCvetovKomand", 					ObnovlenieCvetovKomand);
	AddEventHandler("ObrabotchikObnovlenijaTochekRemonta", 					ObnovlenieTochekRemonta);
	AddEventHandler("ObrabotchikObnovlenijaVidimogoTransporta", 			ObnovlenieVidimogoTransporta);
	AddEventHandler("ObrabotchikObnovlenijaSfer", 							ObnovlenieSfer);
	AddEventHandler("ObrabotchikPodgotovkaUstanovitjTR", 					PodgotovkaUstanovitjTochkuRemonta);
	AddEventHandler("ObrabotchikPogonjaOtremontirovatj", 					PogonjaOtremontirovatj);
	AddEventHandler("ObrabotchikPogonjaZavershitjRemont", 					PogonjaZavershitjRemont);
	AddEventHandler("ObrabotchikVypolnenijaDejstvijaSTS",					VypolnitjDejstvieSTransportom);
	
end

local function onBeamNGTrigger(data)
  --log("E", logTag, "onBeamNGTrigger data="..dumps(data))
  
  --if data.type then
  --   log("E", logTag, "onBeamNGTrigger data="..dumps(data))
--    if data.event == "enter" then onAtStop(data) end
--    if data.event == "exit" then onDepartedStop(data) end
--    if data.event == "tick" then
 --     vehicleCommand(data.subjectID,"bus_onTriggerTick",data)
 --   end
 -- end

end

local function onUpdate(dt)
	
	--if #IdyTransportaNaDobavlenie > 0 then
	--	ProveritTransportDobavlen();
	--end;
	
	SummaDt = SummaDt + dt;
	if SummaDt >= 1 then
		SummaDt = 0;
		-- Вызов каждую секунду
		
		if #IdyTransportaNaDobavlenie > 0 then
			ProveritTransportDobavlen();
		end;
		for _, _ in pairs(IdyTransportaNaYdalenie) do
			ProveritTransportYdalen();
			break;
		end;
		
		
		--ObnovitOgranichenija(true);
		
		--if worldReadyState == 2 then
		--	
		--end;
		
	end;
	
end;

--local sch = 0
local function onPreRender(dt)
	-- Процедура перед отрисовкой кадра, соответственно вызывается каждый кадр
	
	-- Для отладки, чтобы не так быстро выводились сообщения в консоли
	--sch = sch + dt
	--if sch >= 15 then sch = 0 else return end
	
	-- Если нет транспорта на карте
	if be:getObjectCount() == 0 then 
		return; -- Выйти из процедуры
	end;
	
	--ProveritjNastrojki();
	OtrisovatjSfery();
	OtrisovatjNadpisiTransporta();
	OtrisovatjTochkiRemonta();
	
end;

local function onVehicleSpawned(gameVehicleID)
	log('D', 'onVehicleSpawned()', "gameVehicleID = " .. tostring(gameVehicleID));
	table.insert(IdyTransportaNaDobavlenie, gameVehicleID);
end;

local function onVehicleServerSpawned(Param)
	log('D', 'ObnovitVesTransport()', dump(Param));
end;

local function onVehicleResetted(gameVehicleID)
	--[[
	local veh = be:getObjectByID(gameVehicleID);
	if veh then
	--	veh:queueLuaCommand('controller.setFreeze(1)')
		veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end');
	end;
	--]]
end;

local function onVehicleDestroyed(gameVehicleID)
	--log('D', 'onVehicleDestroyed()', "gameVehicleID = " .. tostring(gameVehicleID));
	IdTransportaNaYdalenie = gameVehicleID;
end;

local function onUpdateGFX(dt)
	--log('D', 'onUpdateGFX(dt)', "dt = "..tostring(dt));
end;

local function onExtensionUnloaded()
	-- С последними обновлениями BeamMP - пофиксили эти баги:
	--extensions.core_gamestate.setGameState("freeroam", "freeroam", "freeroam")
	--Lua:requestReload()
end;




M.ObjektVJSON = ObjektVJSON;
M.JSONVObjekt = JSONVObjekt;

M.ObnovitOgranichenijaObschee = ObnovitOgranichenijaObschee;
M.ObnovitOgranichenija = ObnovitOgranichenija;
M.ObnovitVesTransport = ObnovitVesTransport;

M.ProveritTransportDobavlen = ProveritTransportDobavlen;
M.ProveritTransportYdalen = ProveritTransportYdalen;

M.ZaprosSmenyKomandy = ZaprosSmenyKomandy;
M.ZaprosZapuskaPogoni = ZaprosZapuskaPogoni;
M.PodgotovkaZaprosGotovnostj = PodgotovkaZaprosGotovnostj;
M.PodgotovkaZaprosUstanovitjTochkuRemonta = PodgotovkaZaprosUstanovitjTochkuRemonta;
M.PogonjaZaprosRemont = PogonjaZaprosRemont;
M.PogonjaZaprosVyjti = PogonjaZaprosVyjti;
M.PogonjaZaprosNachatjRemont = PogonjaZaprosNachatjRemont;
M.PogonjaZaprosOtkatNaSpavn = PogonjaZaprosOtkatNaSpavn;
M.PogonjaZaprosPrervatjRemont = PogonjaZaprosPrervatjRemont;

M.ObnovitjInterfejsPoUmolchaniju = ObnovitjInterfejsPoUmolchaniju;

M.ObnovlenieOgranichenij = ObnovlenieOgranichenij;
M.ObnovlenieInterfejsa = ObnovlenieInterfejsa;
M.ObnovlenieOperativnojInfyPoTransportu = ObnovlenieOperativnojInfyPoTransportu;
M.ObnovlenieCvetovKomand = ObnovlenieCvetovKomand;
M.ObnovlenieTochekRemonta = ObnovlenieTochekRemonta;
M.ObnovlenieVidimogoTransporta = ObnovlenieVidimogoTransporta;
M.ObnovlenieSfer = ObnovlenieSfer;
M.PogonjaOtremontirovatj = PogonjaOtremontirovatj;
M.PodgotovkaUstanovitjTochkuRemonta = PodgotovkaUstanovitjTochkuRemonta;
M.PogonjaZavershitjRemont = PogonjaZavershitjRemont;
M.VypolnitjDejstvieSTransportom = VypolnitjDejstvieSTransportom;

M.onExtensionLoaded = onExtensionLoaded;
M.onBeamNGTrigger = onBeamNGTrigger;
M.onUpdate = onUpdate;
M.onPreRender = onPreRender;
M.onVehicleSpawned = onVehicleSpawned;
M.onVehicleServerSpawned = onVehicleServerSpawned;
M.onVehicleResetted = onVehicleResetted;
M.onVehicleDestroyed = onVehicleDestroyed;
M.onUpdateGFX = onUpdateGFX;
M.onExtensionUnloaded = onExtensionUnloaded;

return M;
