extends RefCounted
# Локализация: английский текст — это ключ, русский берётся из словаря.
# Loc.t("TEXT")      — обычные строки интерфейса
# Loc.desc(text)     — описания аномалий (собираются по шаблонам, учитывают род)
# Loc.zone(text)     — название зоны ("в вестибюле", "на платформе")

static var _re_cache = {}


static func is_ru() -> bool:
	return str(Game.setting("language")) == "ru"


static func t(s: String) -> String:
	if is_ru() and RU.has(s):
		return RU[s]
	return s


static func zone(z: String) -> String:
	if not is_ru():
		return z
	return ZONES.get(z.to_lower(), z)


static func desc(en: String) -> String:
	if not is_ru():
		return en
	for rule in DESC_RULES:
		var m = _re("(?i)^" + rule[0] + "$").search(en)
		if m:
			return _cap(_fill(rule[1], m, {"g": "f"}))
	return en


static func label(en: String) -> Array:
	var low = en.substr(0, 1).to_lower() + en.substr(1)
	for rule in LABEL_RULES:
		var m = _re("(?i)^" + rule[0] + "$").search(low)
		if m:
			return [_fill(rule[1], m, {"g": rule[2]}), rule[2]]
	return [low, "f"]


static func _re(pattern: String) -> RegEx:
	if not _re_cache.has(pattern):
		_re_cache[pattern] = RegEx.create_from_string(pattern)
	return _re_cache[pattern]


static func _cap(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)


static func _gi(g: String) -> int:
	return {"m": 0, "f": 1, "n": 2, "p": 3}.get(g, 1)


static func _fill(tpl: String, m: RegExMatch, st: Dictionary) -> String:
	var out = ""
	var pos = 0
	for tk in _re(r"\{([^{}]+)\}").search_all(tpl):
		out += tpl.substr(pos, tk.get_start() - pos)
		pos = tk.get_end()
		out += _token(tk.get_string(1), m, st)
	return out + tpl.substr(pos)


static func _token(body: String, m: RegExMatch, st: Dictionary) -> String:
	if body.is_valid_int():
		return m.get_string(int(body))
	if body == "b":
		return ["был", "была", "было", "были"][_gi(st["g"])]
	if body.begins_with("g:"):
		var forms = body.substr(2).split("|")
		return forms[mini(_gi(st["g"]), forms.size() - 1)]
	if body.begins_with("Z:"):
		return zone(m.get_string(int(body.substr(2))))
	if body.begins_with("L:"):
		var r = label(m.get_string(int(body.substr(2))))
		st["g"] = r[1]
		return r[0]
	var parts = body.split(":", true, 1)
	if parts.size() == 2 and parts[0].is_valid_int():
		var val = m.get_string(int(parts[0])).to_lower()
		for pair in parts[1].split(","):
			var kv = pair.split("=", true, 1)
			if kv.size() == 2 and kv[0] == val:
				return kv[1]
		return m.get_string(int(parts[0]))
	return body


const ZONES = {
	"the lobby": "в вестибюле",
	"the first part of the corridor": "в первой части коридора",
	"the middle of the corridor": "в середине коридора",
	"the far end of the corridor": "в дальнем конце коридора",
	"the concourse": "в главном зале",
	"the platform": "на платформе",
	"the near end of the platform": "в ближнем конце платформы",
	"the middle of the platform": "в середине платформы",
	"the far end of the platform": "в дальнем конце платформы",
	"the start of the platform": "в начале платформы",
	"this place": "здесь",
}

# [шаблон английского описания, русский шаблон]. Конкретные правила — выше общих.
# {1} — группа как есть, {1:a=x,b=y} — подстановка по значению группы,
# {Z:1} — зона, {L:1} — название предмета (задаёт род), {b} — был/была/было/были,
# {g:м|ж|ср|мн} — форма по роду предмета.
const DESC_RULES = [
	# ---- отель ----
	[r"The lobby chandelier was switched off\.", "Люстра в вестибюле была выключена."],
	[r"The EXIT sign above the stairwell door was red instead of green\.", "Табличка EXIT над дверью на лестницу была красной вместо зелёной."],
	[r"The green lamp on the reception desk was off\.", "Зелёная лампа на стойке регистрации была выключена."],
	[r"The section with rooms (\d+) and (\d+) was dark — four wall lamps were off\.", "В секции с номерами {1} и {2} было темно: четыре настенные лампы были выключены."],
	[r"The door of room (\d+) was ajar\.", "Дверь номера {1} была приоткрыта."],
	[r"Room (\d+) had the wrong number on its door: (\d+)\.", "На двери номера {1} был неверный номер: {2}."],
	[r"The door of room (\d+) had vanished — only wall remained\.", "Дверь номера {1} исчезла — осталась только стена."],
	[r"A DO NOT DISTURB sign hung on the door of room (\d+)\.", "На двери номера {1} висела табличка «Не беспокоить»."],
	[r"A new door with no number appeared near room (\d+)\.", "Рядом с номером {1} появилась новая дверь без номера."],
	[r"The fire extinguisher was missing — only its sign remained\.", "Огнетушитель пропал — остался только его знак."],
	[r"The fire extinguisher hung in a different place on the wall\.", "Огнетушитель висел на стене в другом месте."],
	[r"An abandoned suitcase stood by the door of room (\d+)\.", "У двери номера {1} стоял брошенный чемодан."],
	[r"An extra side table with a vase stood near room (\d+)\.", "Рядом с номером {1} стоял лишний столик с вазой."],
	[r"A dark stain had appeared on the carpet near room (\d+)\.", "На ковре рядом с номером {1} появилось тёмное пятно."],
	[r"The tall plant in the lobby corner had disappeared\.", "Высокое растение в углу вестибюля исчезло."],
	[r"An armchair in the lobby had been moved and turned\.", "Кресло в вестибюле было передвинуто и повёрнуто."],
	[r"The (left|right) elevator indicator showed (?:floor )?(\w+) instead of 7\.", "Индикатор {1:left=левого,right=правого} лифта показывал этаж {2} вместо 7."],
	[r"The bell on the reception desk was missing\.", "Звонок на стойке регистрации пропал."],
	[r"The lobby clock showed (\S+) instead of (\S+)\.", "Часы в вестибюле показывали {1} вместо {2}."],
	[r"One of the room keys behind the reception desk was missing\.", "Одного из ключей от номеров за стойкой регистрации не хватало."],
	[r"The corridor was longer — an extra section with rooms (\d+) and (\d+) appeared\.", "Коридор стал длиннее — появилась дополнительная секция с номерами {1} и {2}."],
	[r"The corridor ceiling was noticeably lower\.", "Потолок коридора был заметно ниже."],
	[r"The wallpaper on the (left|right) wall near room (\d+) had a different colour\.", "Обои на {1:left=левой,right=правой} стене у номера {2} были другого цвета."],
	[r"A dark figure stood at the far end of the corridor, watching you\.", "В дальнем конце коридора стояла тёмная фигура и наблюдала за тобой."],
	[r"A dark figure stood in the corner of the lobby by the elevators\.", "В углу вестибюля у лифтов стояла тёмная фигура."],
	[r"The (vase|armchair) near room (\d+) was floating in the air\.", "{1:vase=Ваза,armchair=Кресло} у номера {2} {1:vase=парила,armchair=парило} в воздухе."],
	[r"A shadow moved along the wall near room (\d+) with no one to cast it\.", "У номера {1} по стене двигалась тень, хотя отбрасывать её было некому."],
	[r"Footsteps could be heard inside room (\d+)\.", "Из номера {1} доносились шаги."],
	[r"Someone was knocking from inside room (\d+)\.", "Из номера {1} кто-то стучал."],
	[r"Whispering came from behind the door of room (\d+)\.", "Из-за двери номера {1} доносился шёпот."],
	[r"The reception bell kept ringing by itself\.", "Звонок на стойке регистрации звонил сам по себе."],
	# ---- вокзал ----
	[r"The vending machine was switched off\.", "Торговый автомат был выключен."],
	[r"The ticket office windows were dark\.", "Окна кассы были тёмными."],
	[r"The WAY OUT sign glowed red instead of yellow\.", "Знак WAY OUT светился красным вместо жёлтого."],
	[r"The (big clock|hanging clock in the middle of the platform|hanging clock further down the platform) showed (\S+) instead of (\S+)\.", "{1:big clock=Большие часы,hanging clock in the middle of the platform=Подвесные часы в середине платформы,hanging clock further down the platform=Подвесные часы дальше по платформе} показывали {2} вместо {3}."],
	[r"A train was standing on the left track\.", "На левом пути стоял поезд."],
	[r"The windows of the carriage on the right track were lit\.", "Окна вагона на правом пути были освещены."],
	[r"The door of the carriage on the right track was open\.", "Дверь вагона на правом пути была открыта."],
	[r"On the departure board, the (\S+) train was now going to HOLLOWMERE — this very station\.", "На табло отправления поезд {1} теперь шёл до HOLLOWMERE — до этой самой станции."],
	[r"The (\S+) to (.+) was suddenly CANCELLED on the board\.", "Поезд {1} до {2} внезапно оказался ОТМЕНЁН на табло."],
	[r"The departure time of the (.+) train had changed to (\S+)\.", "Время отправления поезда до {1} изменилось на {2}."],
	[r"A motionless passenger stood at the platform edge, watching you\.", "У края платформы неподвижно стоял пассажир и смотрел на тебя."],
	[r"A figure stood on the tracks at the far end of the station\.", "В дальнем конце станции на путях стояла фигура."],
	[r"The platform sign in (.+) pointed to platform 3 instead of 2\.", "Указатель платформы {Z:1} показывал платформу 3 вместо 2."],
	[r"An unattended suitcase stood in the middle of the platform\.", "Посреди платформы стоял бесхозный чемодан."],
	[r"The suitcase on the bench was floating in the air\.", "Чемодан на скамье парил в воздухе."],
	[r"The suitcase in the waiting area was floating in the air\.", "Чемодан в зале ожидания парил в воздухе."],
	[r"A CAUTION WET FLOOR sign appeared on the platform\.", "На платформе появился знак CAUTION WET FLOOR («Осторожно, мокрый пол»)."],
	[r"The station announcement chime kept sounding — but no announcement followed\.", "Звучал сигнал вокзальных объявлений, но самого объявления не следовало."],
	[r"A train could be heard approaching from the tunnel\. None arrived\.", "Было слышно, как из тоннеля приближается поезд. Никакой не приехал."],
	[r"The travel poster in the waiting area had changed: the red sun had turned black\.", "Туристический плакат в зале ожидания изменился: красное солнце стало чёрным."],
	[r"The station sign on the (left|right) wall read (\S+) instead of HOLLOWMERE\.", "Табличка станции на {1:left=левой,right=правой} стене гласила {2} вместо HOLLOWMERE."],
	# ---- метро ----
	[r"The signal at the (near|far) tunnel was green instead of red\.", "Сигнал у {1:near=ближнего,far=дальнего} тоннеля был зелёным вместо красного."],
	[r"The WAY OUT sign was not lit\.", "Знак WAY OUT не светился."],
	[r"A segment of the middle pipe was missing in (.+)\.", "Часть средней трубы отсутствовала {Z:1}."],
	[r"The valve wheel in (.+) was blue instead of red\.", "Маховик вентиля {Z:1} был синим вместо красного."],
	[r"The (station sign near the entrance|station sign in the middle of the platform|big sign across the tracks) read (\S+)\.", "{1:station sign near the entrance=Табличка станции у входа,station sign in the middle of the platform=Табличка станции посередине платформы,big sign across the tracks=Большая табличка через пути} гласила {2}."],
	[r"The far sign across the tracks had an extra .19. on it\.", "На дальней табличке через пути была лишняя «19»."],
	[r"The red emergency cabinet was missing\.", "Красный аварийный шкаф отсутствовал."],
	[r"The fire extinguisher was missing\.", "Огнетушитель отсутствовал."],
	[r"The fire extinguisher had moved along the wall\.", "Огнетушитель сместился вдоль стены."],
	[r"A third STAFF ONLY door appeared in the middle of the platform\.", "Посреди платформы появилась третья дверь STAFF ONLY."],
	[r"A figure stood in the far tunnel, on the tracks\.", "В дальнем тоннеле, на путях, стояла фигура."],
	[r"A figure stood near the end of the platform\.", "Недалеко от конца платформы стояла фигура."],
	[r"Red graffiti .IT SEES YOU. appeared on the wall across the tracks\.", "На стене через пути появилось красное граффити «IT SEES YOU»."],
	[r"A dark puddle appeared on the platform floor\.", "На полу платформы появилась тёмная лужа."],
	[r"A blue barrel stood against the wall near the exit\.", "У стены возле выхода стояла синяя бочка."],
	[r"A loose cable hung from the ceiling\.", "С потолка свисал болтающийся кабель."],
	[r"A handcar stood on the tracks\.", "На путях стояла дрезина."],
	[r"The receiver of the emergency phone was hanging off the hook\.", "Трубка аварийного телефона висела снятой."],
	[r"The line map had an extra black line on it\.", "На схеме линий была лишняя чёрная линия."],
	[r"Knocking echoed from inside the far tunnel\.", "Из дальнего тоннеля раздавался стук."],
	[r"Whispering came from behind the STAFF ONLY door at the far end\.", "Из-за двери STAFF ONLY в дальнем конце доносился шёпот."],
	[r"A train could be heard in the tunnel behind you — on a line closed for 19 years\.", "В тоннеле позади слышался поезд — на линии, закрытой 19 лет."],
	[r"The platform was longer — an extra section appeared before the exit\.", "Платформа стала длиннее — перед выходом появилась дополнительная секция."],
	# ---- жуть (все карты) ----
	[r"Red letters .GET OUT. were smeared on the wall near room (\d+)\.", "У номера {1} на стене кто-то вывел красным: «GET OUT» («УБИРАЙСЯ»)."],
	[r"Red letters .DON'T LOOK BACK. were smeared on the wall near room (\d+)\.", "У номера {1} на стене кто-то вывел красным: «DON'T LOOK BACK» («НЕ ОГЛЯДЫВАЙСЯ»)."],
	[r"Two red eyes watched you from the corner above the exit door\.", "Из угла над дверью выхода на тебя смотрели два красных глаза."],
	[r"A dark figure crept closer every time you looked away\.", "Тёмная фигура подбиралась ближе каждый раз, когда ты отводил взгляд."],
	[r"Dark red liquid was seeping from under the door of room (\d+)\.", "Из-под двери номера {1} сочилась тёмно-красная жидкость."],
	[r"Bloody handprints were smeared on the wall next to the door of room (\d+)\.", "На стене рядом с дверью номера {1} были размазаны кровавые отпечатки ладоней."],
	[r"The air (?:in|at) (.+) was warping — the walls seemed to breathe\.", "Воздух {Z:1} дрожал и плыл — казалось, стены дышат."],
	[r"The door of room (\d+) kept slowly opening and closing by itself\.", "Дверь номера {1} сама медленно открывалась и закрывалась."],
	[r"A heartbeat could be heard through the wall of room (\d+)\.", "Сквозь стену номера {1} было слышно сердцебиение."],
	[r"Something was scratching at the door of room (\d+) from the inside\.", "Что-то скреблось изнутри в дверь номера {1}."],
	[r"Heavy breathing came from the empty lobby\.", "Из пустого вестибюля доносилось тяжёлое дыхание."],
	[r"Huge red letters .NO WAY OUT. were smeared on the wall across the left track\.", "На стене за левым путём огромными красными буквами было написано «NO WAY OUT» («ВЫХОДА НЕТ»)."],
	[r"Huge red letters .LOOK BEHIND YOU. were smeared on the wall across the right track\.", "На стене за правым путём огромными красными буквами было написано «LOOK BEHIND YOU» («ОГЛЯНИСЬ»)."],
	[r"Two red eyes glowed on the right track at the far end of the station\.", "В дальнем конце станции на правом пути светились два красных глаза."],
	[r"A trail of dark red liquid led to the edge of the platform\.", "К краю платформы тянулся след тёмно-красной жидкости."],
	[r"A heartbeat came from beneath the platform\.", "Из-под платформы доносилось сердцебиение."],
	[r"Something was scratching on the inside of the ticket office windows\.", "Что-то скреблось изнутри по окнам кассы."],
	[r"Slow, heavy breathing came out of the far tunnel\.", "Из дальнего тоннеля доносилось медленное тяжёлое дыхание."],
	[r"Red letters .THEY NEVER LEFT. were smeared on the far wall across the tracks\.", "На дальней стене за путями красным было выведено «THEY NEVER LEFT» («ОНИ ТАК И НЕ УШЛИ»)."],
	[r"Two red eyes glowed deep inside the far tunnel\.", "Глубоко в дальнем тоннеле светились два красных глаза."],
	[r"A pool of dark red liquid spread across the platform\.", "По платформе растеклась лужа тёмно-красной жидкости."],
	[r"A heartbeat came from behind the STAFF ONLY door at the start of the platform\.", "Из-за двери STAFF ONLY в начале платформы доносилось сердцебиение."],
	[r"Something was scratching under the edge of the platform\.", "Что-то скреблось под краем платформы."],
	# ---- общие: «<предмет> + действие» ----
	[r"(.+) was upside down\.", "{L:1} {b} {g:перевёрнут|перевёрнута|перевёрнуто|перевёрнуты} вверх ногами."],
	[r"(.+) pulsed red like a heartbeat\.", "{L:1} {g:пульсировал|пульсировала|пульсировало|пульсировали} красным, как бьющееся сердце."],
	[r"(.+) (?:was glowing red|glowed red)\.", "{L:1} {g:светился|светилась|светилось|светились} красным."],
	[r"(.+) glowed green\.", "{L:1} {g:светился|светилась|светилось|светились} зелёным."],
	[r"(.+) was flickering\.", "{L:1} {g:мигал|мигала|мигало|мигали}."],
	[r"(.+) (?:was switched off|was off)\.", "{L:1} {b} {g:выключен|выключена|выключено|выключены}."],
	[r"(.+) was gone\.", "{L:1} {g:пропал|пропала|пропало|пропали}."],
	[r"(.+) had turned red\.", "{L:1} {g:покраснел|покраснела|покраснело|покраснели}."],
	[r"(.+) had withered and turned brown\.", "{L:1} {g:засох и побурел|засохла и побурела|засохло и побурело|засохли и побурели}."],
	[r"(.+) had withered\.", "{L:1} {g:засох|засохла|засохло|засохли}."],
	[r"(.+) had disappeared together with everything on it\.", "{L:1} {g:исчез|исчезла|исчезло|исчезли} вместе со всем, что на {g:нём|ней|нём|них} стояло."],
	[r"(.+) had disappeared\.", "{L:1} {g:исчез|исчезла|исчезло|исчезли}."],
	[r"(.+) had been moved and turned\.", "{L:1} {b} {g:передвинут и повёрнут|передвинута и повёрнута|передвинуто и повёрнуто|передвинуты и повёрнуты}."],
	[r"(.+) was missing\.", "{L:1} {g:отсутствовал|отсутствовала|отсутствовало|отсутствовали}."],
	[r"(.+) was open\.", "{L:1} {b} {g:открыт|открыта|открыто|открыты}."],
	[r"(.+) had stopped spinning\.", "{L:1} {g:остановился|остановилась|остановилось|остановились}."],
	[r"(.+) was red instead of yellow\.", "{L:1} {b} {g:красным|красной|красным|красными} вместо {g:жёлтого|жёлтой|жёлтого|жёлтых}."],
	[r"(.+) had changed\.", "{L:1} {g:изменился|изменилась|изменилось|изменились}."],
	[r"(.+) was painted red instead of green\.", "{L:1} {b} {g:покрашен|покрашена|покрашено|покрашены} в красный цвет вместо зелёного."],
]

# [шаблон названия предмета (с маленькой буквы), русское название, род m/f/n/p]
const LABEL_RULES = [
	# отель
	[r"the (left|right) wall lamp at the start of the corridor", "{1:left=левая,right=правая} настенная лампа в начале коридора", "f"],
	[r"the (left|right) wall lamp by the exit", "{1:left=левая,right=правая} настенная лампа у выхода", "f"],
	[r"the (left|right) wall lamp between rooms (\d+) and (\d+)", "{1:left=левая,right=правая} настенная лампа между номерами {2} и {3}", "f"],
	[r"a wall lamp in the lobby", "настенная лампа в вестибюле", "f"],
	[r"the blue vase on the side table near room (\d+)", "синяя ваза на столике у номера {1}", "f"],
	[r"the small plant on the side table near room (\d+)", "маленькое растение на столике у номера {1}", "n"],
	[r"the stack of books on the side table near room (\d+)", "стопка книг на столике у номера {1}", "f"],
	[r"the side table near room (\d+)", "столик у номера {1}", "m"],
	[r"the potted palm near room (\d+)", "пальма в горшке у номера {1}", "f"],
	[r"the armchair near room (\d+)", "кресло у номера {1}", "n"],
	# вокзал
	[r"the hanging lamp above (.+)", "подвесная лампа {Z:1}", "f"],
	[r"the wall lamp above the (left|right) track in (.+)", "настенная лампа над {1:left=левым,right=правым} путём {Z:2}", "f"],
	[r"a hanging lamp in the waiting area", "подвесная лампа в зале ожидания", "f"],
	[r"the (left|right) bench in the waiting area", "{1:left=левая,right=правая} скамья в зале ожидания", "f"],
	[r"the bench facing the (left|right) track in (.+)", "скамья у {1:left=левого,right=правого} пути {Z:2}", "f"],
	[r"the suitcase on the bench in (.+)", "чемодан на скамье {Z:1}", "m"],
	[r"the travel bag on the platform in (.+)", "дорожная сумка {Z:1}", "f"],
	[r"the suitcase by the right bench", "чемодан у правой скамьи", "m"],
	[r"the bin in the waiting area", "урна в зале ожидания", "f"],
	[r"the bin by the pillar in (.+)", "урна у колонны {Z:1}", "f"],
	[r"the yellow safety line along the (left|right) edge of the platform", "жёлтая линия безопасности вдоль {1:left=левого,right=правого} края платформы", "f"],
	[r"the large poster on the (left|right) wall across the tracks", "большой плакат на {1:left=левой,right=правой} стене через пути", "m"],
	[r"the iron pillar in (.+)", "железная колонна {Z:1}", "f"],
	# метро
	[r"the caged wall lamp in (.+)", "лампа в решётчатом плафоне {Z:1}", "f"],
	[r"the fluorescent tube above (.+)", "люминесцентная лампа {Z:1}", "f"],
	[r"the orange lamp on the far wall across the tracks in (.+)", "оранжевая лампа на дальней стене через пути {Z:1}", "f"],
	[r"the metal bench in (.+)", "металлическая скамья {Z:1}", "f"],
	[r"the STAFF ONLY door in (.+)", "дверь STAFF ONLY {Z:1}", "f"],
	[r"the ventilation fan above the (entrance|exit) door", "вентилятор над {1:entrance=входной,exit=выходной} дверью", "m"],
]

const RU = {
	# --- обучение ---
	"TRAINING": "ОБУЧЕНИЕ",
	"PAUFLIFTER  ·  %d / %d": "ПАУФЛИФТЕР  ·  %d / %d",
	"✓  Done": "✓  Готово. Сигма.",
	"MOUSE": "МЫШЬ",
	"Move the mouse. Look around. 67.": "Двигай мышью. Осмотрись. 67.",
	"W A S D": "W A S D",
	"Press W A S D to walk. Skibidi steps.": "Жми W A S D — иди. Скибиди-шаги.",
	"SHIFT": "SHIFT",
	"Hold SHIFT to run. Gotta go fast.": "Зажми SHIFT — беги. Скорость 67.",
	"F": "F",
	"Press F: flashlight. Lowkey cool.": "Жми F — фонарик. Выглядит круто.",
	"REMEMBER": "ЗАПОМНИ",
	"This corridor is normal. Remember it. Then press E at the far door.": "Этот коридор нормальный. Запомни его. Потом E у дальней двери.",
	"FIND IT": "НАЙДИ",
	"ONE thing changed. Find it. Stuck? Press H. Then E at the door.": "Изменилась ОДНА вещь. Найди. Не выходит? Жми H. Потом E у двери.",
	"REPORT": "ОТЧЁТ",
	"Pick the number with ← →, then CONFIRM. Mistakes are free. No cap.": "Выбери число ← →, потом ПОДТВЕРДИТЬ. Ошибки бесплатно. Без кэпа.",
	"PAUFLIFTER": "ПАУФЛИФТЕР",
	"Yo. I'm Pauflifter. Wanna do a quick training? 30 seconds, no cap.": "Йоу. Я Пауфлифтер. Пройдём быстрое обучение? 30 секунд, без кэпа.",
	"YES, LET'S GO": "ДАВАЙ",
	"NAH, I'M SIGMA": "НЕТ, Я СИГМА",
	"One thing is different here. Find it, then report at the exit.": "Здесь изменилась одна вещь. Найди её и доложи у выхода.",
	"Well done! You found the anomaly and filed the report. That is the whole game: remember, compare, report. Training complete.": "Отлично! Ты нашёл аномалию и сдал отчёт. Это и есть вся игра: запомни, сравни, доложи. Обучение завершено.",
	"Not quite. The training corridor has exactly one anomaly. Back to the reference corridor, look once more.": "Не совсем. В учебном коридоре ровно одна аномалия. Возвращайся в эталонный коридор и посмотри ещё раз.",
	# --- игровой процесс ---
	"[E]  ENTER THE CORRIDOR": "[E]  ВОЙТИ В КОРИДОР",
	"[E]  REPORT ANOMALIES": "[E]  СООБЩИТЬ ОБ АНОМАЛИЯХ",
	"REFERENCE": "ЭТАЛОН",
	"This corridor is normal. Memorize it, then use the door at the end.": "Этот коридор нормальный. Запомни его, затем воспользуйся дверью в конце.",
	"Cleared: %d     Best: %d": "Пройдено: %d     Рекорд: %d",
	"CORRIDOR": "КОРИДОР",
	"PLATFORM": "ПЛАТФОРМА",
	"TUNNEL": "ТОННЕЛЬ",
	"REFERENCE CORRIDOR": "ЭТАЛОННЫЙ КОРИДОР",
	"IT SEES YOU": "ОНО ТЕБЯ ВИДИТ",
	"Run to the exit. Avoid the rifts.": "Беги к выходу. Обходи пространственные дыры.",
	"Everything here is exactly as it should be. Remember it.": "Здесь всё в точности так, как должно быть. Запомни это.",
	"  Press F for your flashlight.": "  Нажми F, чтобы включить фонарик.",
	"Count every difference. Report at the exit.": "Считай каждое отличие. Доложи у выхода.",
	"This is the reference corridor. Nothing here is wrong — yet.": "Это эталонный коридор. Здесь всё в порядке — пока.",
	"You have already used the hint for this corridor.": "Ты уже использовал подсказку в этом коридоре.",
	"Corridor cleared. The next one will be different.": "Коридор пройден. Следующий будет другим.",
	"NEW MAP UNLOCKED:  ": "НОВАЯ КАРТА ОТКРЫТА:  ",
	"  New map unlocked: ": "  Открыта новая карта: ",
	"No mistakes left. The protocol ends here.": "Ошибок не осталось. Протокол завершён.",
	"You will be sent back to the original corridor. Study it again — then try once more.": "Тебя вернут в эталонный коридор. Изучи его заново — и попробуй ещё раз.",
	# --- подсказки ---
	"You sense nothing out of place here.": "Ты не замечаешь здесь ничего странного.",
	"Pay attention to the lighting in %s.": "Обрати внимание на освещение %s.",
	"Pay attention to the walls, doors and ceiling in %s.": "Обрати внимание на стены, двери и потолок %s.",
	"Something that should not exist is in %s.": "Нечто невозможное находится %s.",
	"Stop walking and listen.": "Остановись и прислушайся.",
	"Pay attention to the objects in %s.": "Обрати внимание на предметы %s.",
	# --- HUD ---
	"WASD  MOVE     SHIFT  RUN     F  FLASHLIGHT     E  INTERACT     ESC  PAUSE": "WASD  ХОДЬБА     SHIFT  БЕГ     F  ФОНАРИК     E  ДЕЙСТВИЕ     ESC  ПАУЗА",
	"     H  HINT": "     H  ПОДСКАЗКА",
	"MISTAKES ALLOWED": "ДОПУСТИМО ОШИБОК",
	"OBSERVATION REPORT": "ОТЧЁТ НАБЛЮДЕНИЯ",
	"How many anomalies did you notice?": "Сколько аномалий ты заметил?",
	"← →  or  mouse wheel  ·  keys 0–9  ·  ENTER to confirm": "← →  или  колесо мыши  ·  клавиши 0–9  ·  ENTER — подтвердить",
	"KEEP LOOKING": "ИСКАТЬ ДАЛЬШЕ",
	"CONFIRM": "ПОДТВЕРДИТЬ",
	"CORRECT": "ВЕРНО",
	"INCORRECT OBSERVATION": "НЕВЕРНОЕ НАБЛЮДЕНИЕ",
	"TIME EXPIRED": "ВРЕМЯ ВЫШЛО",
	"Anomalies present:  %d": "Аномалий было:  %d",
	"        You reported:  %d": "        Ты назвал:  %d",
	"WHAT WAS DIFFERENT": "ЧТО ОТЛИЧАЛОСЬ",
	"Nothing. This corridor was exactly as it should be.": "Ничего. Этот коридор был точно таким, каким должен быть.",
	"CONTINUE": "ПРОДОЛЖИТЬ",
	"VIEW RESULTS": "СМОТРЕТЬ ИТОГИ",
	"PAUSED": "ПАУЗА",
	"RESUME": "ВЕРНУТЬСЯ В ИГРУ",
	"SETTINGS": "НАСТРОЙКИ",
	"RESTART RUN": "НАЧАТЬ ЗАНОВО",
	"LEAVE TO MENU": "В ГЛАВНОЕ МЕНЮ",
	"PROTOCOL TERMINATED": "ПРОТОКОЛ ЗАВЕРШЁН",
	"Corridors cleared:  %d": "Пройдено коридоров:  %d",
	"NEW BEST:  %d": "НОВЫЙ РЕКОРД:  %d",
	"Best:  %d": "Рекорд:  %d",
	"Every mistake teaches the eye. Breathe. Look again. Bounce back.": "Каждая ошибка тренирует глаз. Дыши. Смотри снова. Отскочи назад.",
	"TRY AGAIN": "ЕЩЁ РАЗ",
	"MAIN MENU": "ГЛАВНОЕ МЕНЮ",
	# --- главное меню ---
	"ANOMALY  PROTOCOL": "ПРОТОКОЛ  АНОМАЛИЙ",
	"OBSERVE.  REMEMBER.  SURVIVE.": "НАБЛЮДАЙ.  ЗАПОМИНАЙ.  ВЫЖИВАЙ.",
	"PLAY": "ИГРАТЬ",
	"CHASE MODE": "РЕЖИМ ПОГОНИ",
	"[T]  NAH, I'LL LEARN MYSELF": "[T]  НЕТ, Я САМ НАУЧУСЬ",
	"[E]  ESCAPE": "[E]  СБЕЖАТЬ",
	"RUN": "ЗАБЕГ",
	"Something is coming. Get to the exit.": "Что-то приближается. Беги к выходу.",
	"Escaped: %d     Best: %d": "Спасений: %d     Рекорд: %d",
	"Escaped. The next run will be faster.": "Спасён. Следующий забег будет быстрее.",
	"MAP SELECT": "ВЫБОР КАРТЫ",
	"DIFFICULTY": "СЛОЖНОСТЬ",
	"HOW TO PLAY": "КАК ИГРАТЬ",
	"CREDITS": "АВТОРЫ",
	"QUIT": "ВЫХОД",
	"MAP   %s        DIFFICULTY   %s        BEST   %d": "КАРТА   %s        СЛОЖНОСТЬ   %s        РЕКОРД   %d",
	"CORRIDORS CLEARED  %d     MISTAKES  %d     RUNS  %d\nHACK CLUB HAVEN  ·  BOUNCE BACK  ·  v%s": "КОРИДОРОВ ПРОЙДЕНО  %d     ОШИБОК  %d     ЗАБЕГОВ  %d\nHACK CLUB HAVEN  ·  BOUNCE BACK  ·  v%s",
	"Every map is a place to learn by heart. Clear %d corridors in one run to unlock the next map. Completed maps can be replayed at any time.": "Каждая карта — место, которое нужно выучить наизусть. Чтобы открыть следующую карту, пройди за один забег нужное число коридоров (%d). Пройденные карты можно переигрывать в любое время.",
	"RECOMMENDED   ": "РЕКОМЕНДУЕТСЯ   ",
	"BEST   ": "РЕКОРД   ",
	"SELECTED": "ВЫБРАНО",
	"UNLOCKED": "ОТКРЫТО",
	"LOCKED": "ЗАКРЫТО",
	"SELECT": "ВЫБРАТЬ",
	"Clear %d corridors in one run in %s.": "Пройди за один забег нужное число коридоров (%d) на карте %s.",
	"Difficulty changes how subtle the anomalies are, how many can appear at once, how much time you have and how many mistakes you can afford.": "Сложность определяет, насколько незаметны аномалии, сколько их может появиться сразу, сколько у тебя времени и сколько ошибок ты можешь себе позволить.",
	"BEST ON %s   %d": "РЕКОРД (%s)   %d",
	"DEVELOPERS": "РАЗРАБОТЧИКИ",
	"BACK": "НАЗАД",
	# --- настройки ---
	"GRAPHICS": "ГРАФИКА",
	"LOW": "НИЗКАЯ",
	"MEDIUM": "СРЕДНЯЯ",
	"HIGH": "ВЫСОКАЯ",
	"FULLSCREEN": "ПОЛНЫЙ ЭКРАН",
	"VSYNC": "ВЕРТ. СИНХРОНИЗАЦИЯ",
	"HEAD BOB": "ПОКАЧИВАНИЕ КАМЕРЫ",
	"SCREEN EFFECTS": "ЭФФЕКТЫ ЭКРАНА",
	"MOUSE SENSITIVITY": "ЧУВСТВИТЕЛЬНОСТЬ МЫШИ",
	"FIELD OF VIEW": "УГОЛ ОБЗОРА",
	"VOLUME": "ГРОМКОСТЬ",
	"RESET PROGRESS": "СБРОСИТЬ ПРОГРЕСС",
	"CLICK AGAIN TO CONFIRM": "НАЖМИ ЕЩЁ РАЗ ДЛЯ ПОДТВЕРЖДЕНИЯ",
	"PROGRESS RESET": "ПРОГРЕСС СБРОШЕН",
	# --- карты ---
	"THE HOTEL": "ОТЕЛЬ",
	"Meridian Grand - 7th floor": "Meridian Grand — 7-й этаж",
	"A silent luxury corridor. Doors, lamps, paintings - everything is exactly where it should be. Until it is not.": "Тихий роскошный коридор. Двери, лампы, картины — всё стоит там, где должно. Пока не перестанет.",
	"EASY - NORMAL": "ЛЁГКИЙ — СРЕДНИЙ",
	"THE STATION": "ВОКЗАЛ",
	"Hollowmere Terminus - last departure": "Hollowmere Terminus — последний рейс",
	"A terminus where no train has left in years. Clocks, boards and platforms repeat forever - almost.": "Конечная станция, откуда годами не уходил ни один поезд. Часы, табло и платформы повторяются бесконечно — почти.",
	"THE UNDERGROUND": "МЕТРО",
	"Blackwater line - sealed 19 years ago": "Линия Blackwater — закрыта 19 лет назад",
	"A flooded-out metro platform in near darkness. More to watch, less to see. The hardest protocol.": "Затопленная платформа метро почти в полной темноте. Нужно замечать больше, а видно меньше. Самый сложный протокол.",
	# --- сложность ---
	"EASY": "ЛЁГКИЙ",
	"NORMAL": "СРЕДНИЙ",
	"HARD": "СЛОЖНЫЙ",
	"Learn to look.": "Учись смотреть.",
	"Trust your memory.": "Доверяй памяти.",
	"Doubt everything.": "Сомневайся во всём.",
	"Obvious anomalies": "Очевидные аномалии",
	"Up to 2 anomalies per round": "До 2 аномалий за раунд",
	"No time limit": "Без ограничения по времени",
	"3 mistakes allowed": "Допускается 3 ошибки",
	"Optional hints (press H)": "Подсказки по желанию (клавиша H)",
	"Mixed anomaly visibility": "Разная заметность аномалий",
	"Up to 3 anomalies per round": "До 3 аномалий за раунд",
	"3 minutes per round": "3 минуты на раунд",
	"2 mistakes allowed": "Допускается 2 ошибки",
	"No hints": "Без подсказок",
	"Very subtle anomalies": "Очень незаметные аномалии",
	"Up to 4 anomalies per round": "До 4 аномалий за раунд",
	"90 seconds per round": "90 секунд на раунд",
	"1 mistake allowed": "Допускается 1 ошибка",
}
