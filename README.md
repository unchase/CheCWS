![CheCWS logo](https://github.com/unchase/CheCWS/master/Images/checws_logo.png) 


# CheCWS

Утилита CheCWS (Change Wallpeper Silently) предназначена для автоматической смены фона рабочего стола по таймеру (периодичность смены регулируется в настройках).

Для работы программы необходимо:<br/>

- Запустить один из скриптов для запуска на Windows XP или Windows 7 и выше
- При запуске в ОС, поддерживающих [UAC](https://wikipedia.org/wiki/User_Account_Control), под учетной записью, не имеющей административных прав необходимо:
	- отключить [UAC](https://wikipedia.org/wiki/User_Account_Control)
	- убедиться, что служба ["Вторичный вход в систему" ("seclogon")](https://it.wikireading.ru/15588) запущена. 

*Скрипты для запуска в Windows XP и Windows 7, а также для отключения UAC находятся в архиве с программой.*

[![Github Releases](https://img.shields.io/github/downloads/unchase/checws/latest/total.svg?style=flat-square)](https://github.com/unchase/Centurion/releases/latest)

[![GitHub Release Date](https://img.shields.io/github/release-date/unchase/checws.svg?style=flat-square)](https://github.com/unchase/Centurion/releases/latest)

## Supported OS
* Windows XP/Vista/7/8/8.1/10
* Windows Server 2008/2012/2016.

## Current status

Проводится тестирование последней версии релиза.

#### Version 1.0.2

<table>
  <tr>
    <th>&nbsp;</th>
    <th>Windows</th>
    <th>Linux/Mac</th>
  </tr>
  <tr>
    <td>Runtime environment</td>
    <td>MS Windows XP/Vista/7/8/8.1/10<br/>MS Windows Server 2008/2012/2016</td>
    <td>No official support</td>
  </tr>
  <tr>
    <td>Development</td>
    <td>AutoIt 3.3.14.2+</td>
    <td>No official support</td>
  </tr> 
  <tr>
    <td><strong>Latest Release (v1.0.2)</strong></td>
    <td>GitHub: <a href="https://github.com/unchase/checws/releases"><img src="https://img.shields.io/github/downloads/unchase/checws/latest/total.svg?style=flat-square" alt="GitHub Releases (latest)"></a></td>
    <td>No official support</td>
  </tr>
</table>

## Features

- Автоматический выбор фона рабочего стола по таймеру из изображений, расположенных в указанном каталоге.
- Запрет изменения фона рабочего стола и заставки, запуска диспетчера задач, а также приостановки программы и изменения ее настроек для учетных записей, не имеющих административных прав.
- Настройка периодичности таймера (секунды, минуты, часы, дни, месяцы, годы)
- Автозапуск при загрузке системы.

## Links
* Issue tracker: [![GitHub issues](https://img.shields.io/github/issues/unchase/checws/shields.svg?style=flat-square)](https://github.com/unchase/checws/issues) [![GitHub issues-closed](https://img.shields.io/github/issues-closed/unchase/checws.svg?style=flat-square)](https://GitHub.com/unchase/checws/issues?q=is%3Aissue+is%3Aclosed)
* Wiki: <a href="https://github.com/unchase/checws/wiki" rel="nofollow" target="_blank"><img src="https://img.shields.io/badge/Wiki-go-blue.svg?style=flat-square" alt="Github Wiki"></a>
