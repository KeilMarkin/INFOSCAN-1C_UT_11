﻿        
&НаКлиенте
Процедура StartSession(Команда)
	Если УстановитьСоединениеНаСервере(Истина,Ложь) = Ложь Тогда
		ПоказатьОповещениеПользователя("Ошибка подключения",,"Не удалось установить подключение к оборудованию. Проверьте настройки.", БиблиотекаКартинок.НовостиВажные);
		Возврат;
	КонецЕсли;	
	ПодключитьОбработчикОжидания("StartSessionНаКл", 5, Ложь);  
	ПоказатьОповещениеПользователя("Внимание.",,"Начат опрос устройства. Начинайте сканировать товар.", БиблиотекаКартинок.Новости);
КонецПроцедуры

&НаСервере
Функция УстановитьСоединениеНаСервере(ТестСОединения, ЧитатьИсторию)
	  Возврат Обработки.isc_РаботаСУстройством.УстановитьСоединенияНаСервере(ТестСОединения, ЧитатьИсторию);
КонецФункции


&НаКлиенте
Процедура StartSessionНаКл()
	ЗаполнитьТчНаСервере(); 
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьТчНаСервере(ЧитатьИсторию = Ложь)
	соотДанныеСОборудования = ПрочитатьДанныеОборудования(ЧитатьИсторию);
	
	Если соотДанныеСОборудования = Ложь Или Не ЗначениеЗаполнено(соотДанныеСОборудования["barcode"]) Тогда Возврат; КонецЕсли;
	мНайденныхСтрок =  Объект.HistoriOfScaning.НайтиСтроки(Новый Структура("Barcode", соотДанныеСОборудования["barcode"]));
	Если мНайденныхСтрок.Количество() > 0 Тогда 
		//заменим данные в таблице полученными жанными
		стч = мНайденныхСтрок[0];	
	Иначе
		стч = Объект.HistoriOfScaning.Добавить();
	КонецЕсли;	
	стч.Barcode = соотДанныеСОборудования["barcode"];
	стч.Length 	= соотДанныеСОборудования["length"];
	стч.Width 	= соотДанныеСОборудования["width"];
	стч.Height 	= соотДанныеСОборудования["height"];
	стч.Weight 	= соотДанныеСОборудования["weight"];
	стч.Ratio 	= соотДанныеСОборудования["ratio"];
	стч.Status = "Получено";
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ШтрихкодыНоменклатуры.Номенклатура КАК Номенклатура,
	|	ШтрихкодыНоменклатуры.Характеристика КАК Характеристика,
	|	ШтрихкодыНоменклатуры.Упаковка КАК Упаковка
	|ИЗ
	|	РегистрСведений.ШтрихкодыНоменклатуры КАК ШтрихкодыНоменклатуры
	|ГДЕ
	|	ШтрихкодыНоменклатуры.Штрихкод = &Штрихкод";
	Запрос.УстановитьПараметр("Штрихкод", соотДанныеСОборудования["barcode"]);	
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		ЗаполнитьЗначенияСвойств(стч, Выборка);
		стч.Status = "Сопоставлено";
	КонецЦикла;
	
КонецПроцедуры

&НаСервере
Функция ПрочитатьДанныеОборудования(ЧитатьИсторию)
	соотДанныеСОборудования = Новый Соответствие;
	ТелоОтвета =  УстановитьСоединениеНаСервере(Ложь, ЧитатьИсторию);
	
	Если ТелоОтвета = Ложь Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Чтение = Новый ЧтениеJSON;
	Чтение.ОткрытьПоток(ТелоОтвета);
	стк = ПрочитатьJSON(Чтение);
	Если ЧитатьИсторию Тогда
		Для Каждого элемМассива Из стк Цикл
			Для Каждого Параметр из элемМассива Цикл
				Если Найти("length,width,height", НРЕГ(Параметр.Ключ)) > 0 Тогда
					соотДанныеСОборудования.Вставить(Параметр.Ключ, Параметр.Значение * 0.01);	//в сантиметрах измерения переводим в метры
				Иначе
					соотДанныеСОборудования.Вставить(Параметр.Ключ, Параметр.Значение);	
				КонецЕсли;	
				
			КонецЦикла;
		КонецЦикла; 
	Иначе
		Для Каждого Параметр из стк Цикл
			Если Найти("length,width,height", НРЕГ(Параметр.Ключ)) > 0 Тогда
				соотДанныеСОборудования.Вставить(Параметр.Ключ, Параметр.Значение * 0.01);	//в сантиметрах измерения переводим в метры
			Иначе
				соотДанныеСОборудования.Вставить(Параметр.Ключ, Параметр.Значение);	
			КонецЕсли;	
			
		КонецЦикла;
	КонецЕсли;
	
	Если соотДанныеСОборудования.Получить("ratio") = Неопределено Тогда
		соотДанныеСОборудования.Вставить("ratio", 1);
	КонецЕсли;
	Чтение.Закрыть();
	Возврат соотДанныеСОборудования;
	
КонецФункции

&НаКлиенте
Процедура StopSession(Команда)
	ОтключитьОбработчикОжидания("StartSessionНаКл");
	ПоказатьОповещениеПользователя("Внимание.",,"Устройство не опрашивается.");
КонецПроцедуры

&НаСервере
Процедура ЗагрузитьВНоменклатуруНаСервере(стч = Неопределено)
	Если стч = Неопределено Тогда
		Для Каждого строкатабчасти из Объект.HistoriOfScaning Цикл
			ЗаписьВНоменклатуру(строкатабчасти);
		КонецЦикла;
	Иначе
		ЗаписьВНоменклатуру(стч);
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ЗаписьВНоменклатуру(Знач стч)
	
	Настройки = Справочники.isc_Настройки.НайтиПоКоду("000000001");	
	сткВходныеПараметры = Новый Структура("Length, Height, Width, Weight",стч.Length, стч.Height,стч.Width, стч.Weight);
	//Каждое измерение может храниться в различных реквизитах
		Для Каждого стзМетодыХранения Из Настройки.МетодыХранения Цикл
			Если стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.РеквизитыУпаковки Тогда
				ОбъектХранения = стч.Упаковка.ПолучитьОбъект(); 
				ОбъектХранения[стзМетодыХранения.Свойство_ИмяРеквизита] =сткВходныеПараметры[стзМетодыХранения.ИмяСвойства];
				ОбъектХранения.Записать();
			ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.РеквизитыНоменклатуры Тогда
				ОбъектХранения = стч.Номенклатура.ПолучитьОбъект(); 
				ОбъектХранения[стзМетодыХранения.Свойство_ИмяРеквизита] = сткВходныеПараметры[стзМетодыХранения.ИмяСвойства];
				ОбъектХранения.Записать();
			ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.ДопРеквизитыНоменклатуры Тогда
				ОбъектХранения = стч.Номенклатура.ПолучитьОбъект();
				ЗаписатьДопРевизит(ОбъектХранения, стзМетодыХранения.Свойство_ИмяРеквизита, сткВходныеПараметры[стзМетодыХранения.ИмяСвойства]);			ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.ДопРеквизитыХарактеристики Тогда
				ОбъектХранения.Записать();
			ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.ДопРеквизитыХарактеристики Тогда
				Если ЗначениеЗаполнено(стч.Характеристика) Тогда
					ОбъектХранения = стч.Характеристика.ПолучитьОбъект(); 
				Иначе 
					ОбъектХранения = стч.Номенклатура.ПолучитьОбъект();
				КонецЕсли;
			ЗаписатьДопРевизит(ОбъектХранения, стзМетодыХранения.Свойство_ИмяРеквизита, сткВходныеПараметры[стзМетодыХранения.ИмяСвойства]);
			ОбъектХранения.Записать();
		ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.ДопСведенияНоменклатуры Тогда
			РС = РегистрыСведений.ДополнительныеСведения.СоздатьМенеджерЗаписи();
			РС.Объект = стч.Номенклатура; 
			РС.Свойство = стзМетодыХранения.Свойство_ИмяРеквизита;
			РС.Значение = сткВходныеПараметры[стзМетодыХранения.ИмяСвойства];
		ИначеЕсли стзМетодыХранения.МетодХраненияВГХ = Перечисления.isc_МетодХраненияВГХ.ДопСведенияХарактеристики Тогда
			РС = РегистрыСведений.ДополнительныеСведения.СоздатьМенеджерЗаписи();
			Если ЗначениеЗаполнено(стч.Характеристика) Тогда
					РС.Объект = стч.Характеристика; 
				Иначе 
					РС.Объект = стч.Номенклатура;
				КонецЕсли;
 
			РС.Свойство = стзМетодыХранения.Свойство_ИмяРеквизита;
			РС.Значение = сткВходныеПараметры[стзМетодыХранения.ИмяСвойства];	
			КонецЕсли;
				
		стч.Status = "Сохранено";		
		КонецЦикла;
	
	   КонецПроцедуры

	   Процедура ЗаписатьДопРевизит(ОбъектЗаписи, ДопРеквизит, Значение)
		   СтрДопРек = ОбъектЗаписи.ДополнительныеРеквизиты.Найти(ДопРеквизит,"Свойство");
		   Если ЗначениеЗаполнено(СтрДопРек)Тогда
			   СтрДопРек.Значение = Значение; 
		   Иначе
			   СтрДопРек = ОбъектЗаписи.ДополнительныеРеквизиты.Добавить();
			   СтрДопРек.Свойство = ДопРеквизит;
			   СтрДопРек.Значение = Значение;
		   КонецЕсли;
		   ОбъектЗаписи.Записать();
	   КонецПроцедуры

&НаКлиенте
Процедура ЗагрузитьВНоменклатуру(Команда)
	ПоказатьВопрос(Новый ОписаниеОповещения("СохранитьВБазу", ЭтотОбъект), "Данные будут записаны согласно настройкам.Данные в реквизитах будут перезаписаны. Продолжить?", РежимДиалогаВопрос.ДаНет,,, "Предупреждение");
КонецПроцедуры

&НаКлиенте
Процедура СохранитьВБазу(РезультатВопроса, ПараметрыЗаписи) Экспорт	
	Если РезультатВопроса = КодВозвратаДиалога.Да Тогда
		ЗагрузитьВНоменклатуруНаСервере();
		ПоказатьОповещениеПользователя("Операция завершена.");
	КонецЕсли;	
КонецПроцедуры


&НаКлиенте
Процедура ТестСоединения(Команда)
	УспешноПодключились = УстановитьСоединениеНаСервере(Истина, Ложь);
	Если УспешноПодключились Тогда
		ПоказатьОповещениеПользователя("Успешно!",,"Успешно подключение к устройству.", БиблиотекаКартинок.ПиктограммаПоказателяЦельДостигнута);	
	Иначе
		ПоказатьОповещениеПользователя("Ошибка подключения",,"Не удалось установить подключение к оборудованию. Проверьте настройки.", БиблиотекаКартинок.НовостиВажные);
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Процедура ОчиститьТЧ(Команда)
	Объект.HistoriOfScaning.Очистить();
КонецПроцедуры

&НаКлиенте
Процедура ВыгрузитьВCSV(Команда)
	ДиалогВыбораФайла=Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);  // выбор каталога
	ДиалогВыбораФайла.Заголовок = "Укажите имя файла выгрузки!";
	Если ДиалогВыбораФайла.Выбрать() Тогда
		Путь = ДиалогВыбораФайла.ПолноеИмяФайла + ".csv";    // присваиваем переменной путь выбранного каталога + имя будущего файла    
		т = Новый ТекстовыйДокумент;
		т.УстановитьТекст(СформироватьИВернутьCSV());
		Попытка
			т.Записать(Путь);
			ПоказатьОповещениеПользователя("Успешно!",,"Файл сохранен.");
		Исключение
			
		КонецПопытки;	
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Функция СформироватьИВернутьCSV()
	ТекстCSV = "Barcode;Length;Width;Height;Weight;Ratio;КодНоменклатуры;" + Символы.ПС;;
	Для Каждого стч Из Объект.HistoriOfScaning Цикл
		ТекстCSV = ТекстCSV + 
		стч.Barcode + ";" +
		стч.Length + ";" +
		стч.Width + ";" +
		стч.Height + ";" +
		стч.Weight + ";" +
		стч.Ratio + ";" +
		стч.Номенклатура + ";" +
		Символы.ПС;
	КонецЦикла;	
	Возврат ТекстCSV;
КонецФункции	

&НаКлиенте
Процедура ПрочитатьИсториюИзмерений(Команда)
	ЗаполнитьТчНаСервере(Истина);
КонецПроцедуры

