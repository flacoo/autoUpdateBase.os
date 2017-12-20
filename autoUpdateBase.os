﻿﻿///////////////////////////////////////////////////////////////////////////////
// Обновление ИБ из хранилища с выполнением автотестов
//
// Получает последнюю закладку хранилище, блокирует начало сеансов
// обновляет кофигурацию, освобождает блокировку сеансов, запускает автотесты, 
// парсиn логи ТЖ и отправляет письмо на e-mail

#Использовать v8runner
#Использовать InternetMail

Перем СЕРВЕР;
Перем БАЗЫ;
Перем БАЗА;
Перем ПОЛЬЗОВАТЕЛЬ;
Перем ПАРОЛЬ;
Перем ПЛАТФОРМА_ВЕРСИЯ;
Перем ХРАНИЛИЩЕ_ПУТЬ;
Перем ХРАНИЛИЩЕ_ПОЛЬЗОВАТЕЛЬ;
Перем ХРАНИЛИЩЕ_ПАРОЛЬ;
Перем КОМ_КОННЕКТОР;
Перем Лог;
Перем РАБОЧИЙ_КАТАЛОГ;

///////////////////////////////////////////////////////////////////////////////
// ПРОГРАМНЫЙ ИНТЕРФЕЙС

// В функции задаются параметры базы, которую требуется обновить
Функция Инициализировать()
    СЕРВЕР = "ИМЯ СЕРВЕРА"; //MYSRV
    БАЗЫ = Новый Массив;
    БАЗЫ.Добавить("ИМЯ ОБНОВЛЯЕМОЙ БАЗЫ"); //MYBASE
    ПОЛЬЗОВАТЕЛЬ = "ПОЛЬЗОВАТЕЛЬ ОБНОВЛЯЕМОЙ БАЗЫ"; //USER
    ПАРОЛЬ = "ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ ОБНОВЛЯЕМОЙ БАЗЫ"; //"PASSWRD"
    ПЛАТФОРМА_ВЕРСИЯ = "ВЕРСИЯ ПЛАТФОРМЫ"; // Например 8.3.10.2580, необязательно
    ХРАНИЛИЩЕ_ПУТЬ = "ПУТЬ К КАТАЛОГУ ХРАНИЛИЩА КОНФИГУРАЦИИ"; // \\MYBASE\ConfigurationStorage1C\
    ХРАНИЛИЩЕ_ПОЛЬЗОВАТЕЛЬ = "ПОЛЬЗОВАТЕЛЬ ХРАНИЛИЩА"; // UPD
    ХРАНИЛИЩЕ_ПАРОЛЬ = "ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ ХРАНИЛИЩА"; // ""
    КОМ_КОННЕКТОР = "V83.COMConnector";
    РАБОЧИЙ_КАТАЛОГ = "D:\scripts\"; // каталог в котором находятся каталоги с xUnitFor1C и v8LogScanner, должен заканчиваться слешем!!

    Лог = Логирование.ПолучитьЛог("oscript.lib.AutoUpdateIB");
КонецФункции

Процедура ОбновитьИБВПопытке() Экспорт

    ИмяЛогФайла = "logs/log_" + Формат(ТекущаяДата(), "ДФ=ddMMyy") + ".log";
    Для каждого БАЗА Из БАЗЫ Цикл
        Попытка

            Начало = ТекущаяДата();

            СоздатьЛогФайл(ИмяЛогФайла);

            ОбновитьИБ();

            Конец = ТекущаяДата();
            ДлительностьМинут = Окр(Число(Конец - Начало) / 60);

            исхИмяФайлаТестов = "";
            ИнфоПоТестам = ЗапуститьТесты(исхИмяФайлаТестов);
            исхИмяФайлаРезультатов = "";
            ИнфоПоТЖ = ЗапуститьV8LogScanner(исхИмяФайлаРезультатов); 

            Лог.Закрыть();

            ТекстПисьма = "1.Автообновление базы " + БАЗА + " выполнено успешно!
            |<br>Длительность - " + Строка(ДлительностьМинут) + " минут.
            |<br>Подробности во вложении.
            |<p>" + ИнфоПоТестам + "
            |<p>" + ИнфоПоТЖ;

            Вложения = Новый Массив;
            Вложения.Добавить(ИмяЛогФайла);
            Вложения.Добавить(исхИмяФайлаРезультатов);
            ОтправитьПисьмо("Автообновление " + БАЗА + " " + Формат(Начало, "ДФ=dd.MM.yy"), ТекстПисьма, Вложения);

            ВрФайлы = Новый Массив;
            ВрФайлы.Добавить(ИмяЛогФайла);
            ВрФайлы.Добавить(исхИмяФайлаРезультатов);
            ВрФайлы.Добавить(исхИмяФайлаТестов);
            ОчиститьВременныеФайлы(ВрФайлы);

        Исключение

            ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());

            ТекстПисьма = "Возникла ошибка при автообновление базы " + БАЗА + "!
            |<p>Текст ошибки: " + ТекстОшибки + "
            |<p>Подробности в логе на сервере. Относительный путь: " + ИмяЛогФайла;

            ОтправитьПисьмо("Автообновление " + БАЗА + " " + Формат(Начало, "ДФ=dd.MM.yy"), ТекстПисьма);

        КонецПопытки
    КонецЦикла;

КонецПроцедуры

///////////////////////////////////////////////////////////////////////////////
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ОБНОВЛЕНИЯ И БЛОКИРОВКИ ИБ

Процедура ОбновитьИБ()
    
        Лог.Информация(Строка(ТекущаяДата()) + " Инициализация конфигуратора...");
    
        Конфигуратор = Новый УправлениеКонфигуратором();
        Конфигуратор.УстановитьКонтекст(
            "/IBConnectionString""Srvr=" + СЕРВЕР + ";Ref='"+ БАЗА + "'""", ПОЛЬЗОВАТЕЛЬ, ПАРОЛЬ
        );
        Конфигуратор.ИспользоватьВерсиюПлатформы(ПЛАТФОРМА_ВЕРСИЯ);
        Конфигуратор.УстановитьКлючРазрешенияЗапуска("ПакетноеОбновлениеКонфигурацииИБ");
    
        Лог.Информация(Строка(ТекущаяДата()) + " Получение из хранилища...");
    
        Конфигуратор.ПолучитьИзмененияКонфигурацииБазыДанныхИзХранилища(ХРАНИЛИЩЕ_ПУТЬ, ХРАНИЛИЩЕ_ПОЛЬЗОВАТЕЛЬ, ХРАНИЛИЩЕ_ПАРОЛЬ);
    
        Лог.Информация(Строка(ТекущаяДата()) + " Завершение сеансов...");
        ЗавершитьСеансыИУстановитьБлокировку();
    
        Лог.Информация(Строка(ТекущаяДата()) + " Обновление базы ...");
    
        Конфигуратор.ОбновитьКонфигурациюБазыДанных();
    
        Лог.Информация(Строка(ТекущаяДата()) + " Снятие блокировки начала сеансов...");
        СнятьБлокировкуСеансовИЗаданийИнформационнойБазы();
        
        Лог.Информация("ОК");
    
    КонецПроцедуры

Процедура ЗавершитьСеансыИУстановитьБлокировку()

    Соединение = УстановитьВнешнееСоединениеСБазой();

    Соединение.СоединенияИБ.УстановитьБлокировкуСоединений(
        НСтр("ru = 'в связи с необходимостью обновления конфигурации.'"), "ПакетноеОбновлениеКонфигурацииИБ");

    ПараметрыАдминистрирования = Соединение.СоединенияИБВызовСервера.ПараметрыАдминистрирования();
    ПараметрыАдминистрирования.АдресАгентаСервера = СЕРВЕР;
    ПараметрыАдминистрирования.ИмяАдминистратораИнформационнойБазы = ПОЛЬЗОВАТЕЛЬ;
    ПараметрыАдминистрирования.ИмяВКластере = БАЗА;
    ПараметрыАдминистрирования.ПарольАдминистратораИнформационнойБазы = ПАРОЛЬ;
    ПараметрыАдминистрирования.ТипПодключения = "COM";

    Соединение.АдминистрированиеКластераКлиентСервер.УдалитьСеансыИнформационнойБазы(ПараметрыАдминистрирования);
    // Альтернативный вариант
    //Соединение.СоединенияИБКлиентСервер.УдалитьВсеСеансыКромеТекущего(ПараметрыАдминистрирования);

КонецПроцедуры

Процедура СнятьБлокировкуСеансовИЗаданийИнформационнойБазы()

    Соединение = УстановитьВнешнееСоединениеСБазой();
    Соединение.СоединенияИБ.РазрешитьРаботуПользователей();

КонецПроцедуры

// Устанавливает внешнее соединение с информационной базой по переданным параметрам подключения и возвращает указатель
    // на это соединение.
    //
    // Параметры:
    //  ПараметрыПодключения - Структура - Параметры подключения к информационной базе (см. в ОбновитьИнформационнуюБазу()).
    //
    // Возвращаемое значение:
    //  COMОбъект, Неопределено - указатель на COM-объект соединения или Неопределено в случае ошибки;
    //
Функция УстановитьВнешнееСоединениеСБазой(АутентификацияОперационнойСистемы = Ложь, ФайловыйВариантРаботы = Ложь)

        Попытка
            COMОбъект = Новый COMОбъект(КОМ_КОННЕКТОР);
        Исключение
            Лог.Ошибка(СтрШаблон(НСтр("ru = 'Не удалось подключится к другой программе:
                |%1'"), ИнформацияОбОшибке()));
            Возврат Неопределено;
        КонецПопытки;

        // Формирование строки соединения.
        ШаблонСтрокиСоединения = "[СтрокаБазы][СтрокаАутентификации];UC=ПакетноеОбновлениеКонфигурацииИБ";

        Если ФайловыйВариантРаботы Тогда
            СтрокаБазы = "File = ""&КаталогИнформационнойБазы""";
            СтрокаБазы = СтрЗаменить(СтрокаБазы, "&КаталогИнформационнойБазы", БАЗА);
        Иначе
            СтрокаБазы = "Srvr = ""&ИмяСервера1СПредприятия""; Ref = ""&ИмяИнформационнойБазыНаСервере1СПредприятия""";
            СтрокаБазы = СтрЗаменить(СтрокаБазы, "&ИмяСервера1СПредприятия",                     СЕРВЕР);
            СтрокаБазы = СтрЗаменить(СтрокаБазы, "&ИмяИнформационнойБазыНаСервере1СПредприятия", БАЗА);
        КонецЕсли;

        Если АутентификацияОперационнойСистемы Тогда
            СтрокаАутентификации = "";
        Иначе
            СтрокаАутентификации = "; Usr = ""&ИмяПользователя""; Pwd = ""&ПарольПользователя""";
            СтрокаАутентификации = СтрЗаменить(СтрокаАутентификации, "&ИмяПользователя",    ПОЛЬЗОВАТЕЛЬ);
            СтрокаАутентификации = СтрЗаменить(СтрокаАутентификации, "&ПарольПользователя", ПАРОЛЬ);
        КонецЕсли;

        СтрокаСоединения = СтрЗаменить(ШаблонСтрокиСоединения, "[СтрокаБазы]", СтрокаБазы);
        СтрокаСоединения = СтрЗаменить(СтрокаСоединения, "[СтрокаАутентификации]", СтрокаАутентификации);

        Попытка
            Соединение = COMОбъект.Connect(СтрокаСоединения);
        Исключение
            Лог.Ошибка(СтрШаблон(НСтр("ru = 'Не удалось подключится к другой программе:
                |%1'"), ИнформацияОбОшибке()));
            Возврат Неопределено;
        КонецПопытки;

        Возврат Соединение;

КонецФункции

///////////////////////////////////////////////////////////////////////////////
// АВТОТЕСТЫ

Функция ЗапуститьТесты(исхИмяФайлаТестов)

    Лог.Информация(Строка(ТекущаяДата()) + " Запуск автотестов...");

    исхИмяФайлаТестов =  РАБОЧИЙ_КАТАЛОГ + "testReport.xml";

    Конфигуратор = Новый УправлениеКонфигуратором();
    Конфигуратор.УстановитьКонтекст(
        "/IBConnectionString""Srvr=" + СЕРВЕР + ";Ref='"+ БАЗА + "'""", ПОЛЬЗОВАТЕЛЬ, ПАРОЛЬ
    );
    Конфигуратор.ИспользоватьВерсиюПлатформы(ПЛАТФОРМА_ВЕРСИЯ);

    Конфигуратор.ЗапуститьВРежимеПредприятия(, Истина, "/Execute """+ РАБОЧИЙ_КАТАЛОГ + "xUnitFor1c\xddTestRunner.epf"" /C ""xddRun ЗагрузчикКаталога " + РАБОЧИЙ_КАТАЛОГ + "tests" + "; xddReport ГенераторОтчетаJUnitXML " + исхИмяФайлаТестов + "; xddShutdown""");
    // если хочется грузить тесты из подсистемы
    //Конфигуратор.ЗапуститьВРежимеПредприятия(, Истина, "/Execute """+ РАБОЧИЙ_КАТАЛОГ + "xUnitFor1c\xddTestRunner.epf"" /C ""xddRun ЗагрузчикИзПодсистемКонфигурации Метаданные.Подсистемы.Акита.Подсистемы.Администрирование.Подсистемы.xUnitFor1C.Подсистемы.Tests;  xddReport ГенераторОтчетаJUnitXML " + исхИмяФайлаТестов + "; xddShutdown""");
    
    Лог.Информация(Строка(ТекущаяДата()) + " Автотесты выполнены.");

    Возврат ПрочитатьРезультатТестовИзФайла();

КонецФункции
    
Функция ПрочитатьРезультатТестовИзФайла() 

    ИМЯ_ФАЙЛА_ТЕСТОВ =  РАБОЧИЙ_КАТАЛОГ + "testreport.xml";
    
    TEST_SUITES = "testsuites";
    
    TIME = "time";
    TESTS = "tests";
    FAILURES = "failures";
    ERRORS = "errors";
    SKIPPED = "skipped";
    TESTCASE = "testcase";
    CLASSNAME = "classname";
    STATUS = "status";
    NAME   = "name";
    
    ЧтениеXML = Новый ЧтениеXML();
    ЧтениеXML.ОткрытьФайл(ИМЯ_ФАЙЛА_ТЕСТОВ);
    
    СтатистикаТестов = Новый Структура;
    СтатистикаТестов.Вставить("ЗаголовокРезультата");
    СтатистикаТестов.Вставить("РезультатыТестов", Новый Массив);
    
    Пока ЧтениеXML.Прочитать() Цикл
        Если ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента И ЧтениеXML.Имя= TEST_SUITES Тогда
            ЗаголовокРезультата = Новый Массив;
            
            ЗаголовокРезультата.Добавить("Длительность(сек): " + ЧтениеXML.ПолучитьАтрибут(TIME));
            ЗаголовокРезультата.Добавить("Тестов: " + ЧтениеXML.ПолучитьАтрибут(TESTS));
            ЗаголовокРезультата.Добавить("Провалено: " + ЧтениеXML.ПолучитьАтрибут(FAILURES));
            ЗаголовокРезультата.Добавить("Ошибок: " + ЧтениеXML.ПолучитьАтрибут(ERRORS));
            ЗаголовокРезультата.Добавить("Пропущено: " + ЧтениеXML.ПолучитьАтрибут(SKIPPED));
            
            СтатистикаТестов.ЗаголовокРезультата = СтрСоединить(ЗаголовокРезультата, " ");
            
        ИначеЕсли ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента И ЧтениеXML.Имя = TESTCASE Тогда
            
            ИмяОбработкиТеста = ЧтениеXML.ПолучитьАтрибут(CLASSNAME);
            ИмяМетодаТеста = ЧтениеXML.ПолучитьАтрибут(NAME);
            СтатусТеста = ВРЕГ(СокрЛП(ЧтениеXML.ПолучитьАтрибут(STATUS)));
            ВремяТеста = ЧтениеXML.ПолучитьАтрибут(TIME);
            

            ШаблонТеста = "<div><div style=""background-color:%1; width:70px; float: left"">%2</div>%3</div>";
            Если СтатусТеста = "ERROR" Тогда
                ЦветСтатуса = "#f08080";
            ИначеЕсли СтатусТеста = "FAILURE" Тогда
                ЦветСтатуса = "#ffff00";
            Иначе
                ЦветСтатуса = "#90ee90";
            КонецЕсли;
            
            ПредставлениеЦветаСтатуса = СтрЗаменить(ШаблонТеста, "%1", ЦветСтатуса);
            ПредставлениеСтатуса = СтрЗаменить(ПредставлениеЦветаСтатуса, "%2", СтатусТеста);
            ПредставлениеТеста = СтрЗаменить(ПредставлениеСтатуса, "%3", " Тест:" + ИмяОбработкиТеста + " - " +  ИмяМетодаТеста + " Время: " + ВремяТеста); 

            СтатистикаТестов.РезультатыТестов.Добавить(ПредставлениеТеста);
            
        КонецЕсли;
    КонецЦикла;
    
    ЧтениеXML.Закрыть();

    ТекстИнфо = 
    "2.Автоматические unit-тесты:"
    + "<br>" + СтатистикаТестов.ЗаголовокРезультата
    + "<br>" 
    + "<br>Подробности:"
    + "<br>" + СтрСоединить(СтатистикаТестов.РезультатыТестов, "<br>");

    Возврат ТекстИнфо;

КонецФункции

///////////////////////////////////////////////////////////////////////////////
// V8LOGSCANNER

Функция ЗапуститьV8LogScanner(исхИмяФайлаРезультатов = "")

    Лог.Информация(Строка(ТекущаяДата()) + " Запуск v8LogScanner...");

    КАТАЛОГ_V8LogScanner = РАБОЧИЙ_КАТАЛОГ + "v8LogScanner\"; 
    
    исхИмяФайлаРезультатов = КАТАЛОГ_V8LogScanner + "v8LogScanner_result.txt";

    ЗапуститьПриложение(КАТАЛОГ_V8LogScanner + "run_client_EXEC.cmd", КАТАЛОГ_V8LogScanner, Истина);

    ЧтениеФайла = Новый ЧтениеТекста(исхИмяФайлаРезультатов);
    ПрочитанныеСтроки = Новый Массив;

    СтрокаФайла = "";
    СчетчикСтрок = 0;
    Пока СтрокаФайла <> Неопределено Или СчетчикСтрок < 100 Цикл
        СтрокаФайла = ЧтениеФайла.ПрочитатьСтроку();
        
        Если СтрНайти(ВРег(СтрокаФайла), "FIRST TOP 100 KEYS") <> 0 Тогда
            Прервать;
        КонецЕсли;
        ПрочитанныеСтроки.Добавить(СтрокаФайла);    
            СчетчикСтрок = СчетчикСтрок + 1;
    КонецЦикла;
    ЧтениеФайла.Закрыть();
    ИнфоПоТЖ = "<p>3.Анализ логов ТЖ с помощью V8 Log Scanner 1.2.<br>";
    ИнфоПоТЖ = ИнфоПоТЖ + СтрСоединить(ПрочитанныеСтроки, "<br>");
    ИнфоПоТЖ = ИнфоПоТЖ + "<p>См. подробности во вложении";

    Лог.Информация(Строка(ТекущаяДата()) + " Завершение работы v8LogScanner");

    Возврат ИнфоПоТЖ; 

КонецФункции

///////////////////////////////////////////////////////////////////////////////
// ФУНКЦИИ УТИЛИТЫ

Процедура СоздатьЛогФайл(ИмяФайла)

    СоздатьКаталог("logs");
    
    ФайлЖурнала = Новый ВыводЛогаВФайл;
    ФайлЖурнала.ОткрытьФайл(ИмяФайла);
    Лог.ДобавитьСпособВывода(ФайлЖурнала);

КонецПроцедуры

Процедура ОтправитьПисьмо(Тема, ТекстHTML, Вложения = Неопределено)

        Профиль = Новый ИнтернетПочтовыйПрофиль;

        Профиль.АдресСервераSMTP    = "127.0.0.1"; // укажите свои данные
        Профиль.ПользовательSMTP    = ""; // укажите свои данные
        Профиль.ПарольSMTP          = ""; // укажите свои данные
        Профиль.ПортSMTP            = 25; // укажите свои данные
        Профиль.ИспользоватьSSLSMTP = Ложь; // укажите свои данные

        Профиль.АдресСервераPOP3    = "127.0.0.1";  // укажите свои данные
        Профиль.ИспользоватьSSLPOP3 = Ложь; // укажите свои данные
        Профиль.Пользователь        = ""; // укажите свои данные
        Профиль.Пароль              = ""; // укажите свои данные

        Сообщение = Новый ИнтернетПочтовоеСообщение;
        Сообщение.Получатели.Добавить("receiver@company.ru"); // укажите свои данные
        Сообщение.ОбратныйАдрес.Добавить("sender@company.ru"); // укажите свои данные
        Сообщение.Отправитель = "sender@company.ru"; // укажите свои данные
        Сообщение.Тема        = Тема;

        Сообщение.Тексты.Добавить(ТекстHTML, ТипТекстаПочтовогоСообщения.HTML);
        Если Вложения <> Неопределено Тогда
            Для каждого ФайлВложения Из Вложения Цикл
                Сообщение.Вложения.Добавить(ФайлВложения);
            КонецЦикла;
        КонецЕсли;

        Почта = Новый ИнтернетПочта;
        Почта.Подключиться(Профиль, ПротоколИнтернетПочты.POP3);
        Почта.Послать(Сообщение, , ПротоколИнтернетПочты.SMTP);

КонецПроцедуры

Процедура ОчиститьВременныеФайлы(ИменаФайлов)

    Попытка 
        Для каждого ИмяФайла Из ИменаФайлов Цикл
            УдалитьФайлы(ИмяФайла);
        КонецЦикла;
    Исключение
        // ничего не делаем
    КонецПопытки;

КонецПроцедуры

Инициализировать();
ОбновитьИБВПопытке();
