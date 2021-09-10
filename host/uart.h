#ifndef EMITTER_H
#define EMITTER_H
 
#include <QSerialPort>
 
class Uart
{

public:
    Uart();
    // Функция проверки соединения.
    bool isConnected() const;
    QByteArray writeAndRead();
private:
    // Функция подключения.
    void connectToEmitter();


    

    const quint8 STARTBYTE = 0x40;  // Начало посылки.
    const quint8 DEV = 0;  // ID - излучателя.
 
    // Доступные нам команды, отправляемые излучателю. Отправляется третьим байтом в посылке.
    enum class Command : quint8
    {
        S = 0x53, // Команда запрос статуса.
        P = 0x50, // Команда установки параметров.
        N = 0x4e, // Команда включения рентгена.
        F = 0x46  // Команда выключения рентгена.
    };
 
    // Сообщения излучателя.
    enum class MessageCommandS : quint8
    {
        OK = 0x00, // Все ок.
        XRAY_ON = 0x01, // Излучение включено.
        XRAY_STARTING = 0x02, // Выход излучателя на режим.
        XRAY_TRAIN = 0x03, // Идет тренировка.
        COOLING = 0x04 // Охлаждение.
    };
 
    // Ошибки излучателя.
    enum class ErrorCommandS : quint8
    {
        NO_ERROR = 0x00, // Нет ошибок.
        XRAY_CONTROL_ERROR = 0x01, // Ошибка управления рентгеновской трубкой.
        MODE_ERROR = 0x02, // Ошибка установки заданного режима.
        VOLTAGE_ERROR = 0x03, // Превышение порога напряжения.
        CURRENT_ERROR = 0x04, // Превышение порога по току.
        PROTECTIVE_BOX_ERROR = 0x05, // Защитный бокс открыт.
        LOW_SUPPLY_VOLTAGE = 0x06, // Низкое питающее напряжение.
        DISCONNECTION = 0x07, // Отсутствие подтверждения соединения (более 1 с)ю
        OVERHEAT = 0x08 // Перегрев.
    };
 
    QSerialPort *m_pSerialPort;
    bool m_isConnected;
};
 
#endif // EMITTER_H