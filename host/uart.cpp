#include "uart.h"
 
#include <QDebug>
 
Uart::Uart()
{
    // Инициализация последовательного порта.
    m_pSerialPort = new QSerialPort();
    m_pSerialPort->setPortName("COM3");
    // Скорость передачи данных. 19200 бит/с.
    m_pSerialPort->setBaudRate(QSerialPort::Baud19200);
    m_pSerialPort->setDataBits(QSerialPort::Data8);
    m_pSerialPort->setParity(QSerialPort::NoParity);
    m_pSerialPort->setStopBits(QSerialPort::OneStop);
    m_pSerialPort->setFlowControl(QSerialPort::NoFlowControl);
 
    connectToEmitter();
}
 
bool Uart::isConnected() const
{
    return m_isConnected;
}
 
void Uart::connectToEmitter()
{
    if (m_pSerialPort->open(QSerialPort::ReadWrite))
        m_isConnected = true;
    else
        m_isConnected = false;
}
 
QByteArray Uart::writeAndRead()
{

    QByteArray sentData;
    sentData.resize(6);
    sentData[0] = STARTBYTE;
    sentData[1] = DEV;
 
    m_pSerialPort->write(sentData);
    m_pSerialPort->waitForBytesWritten(100);
 
    m_pSerialPort->waitForReadyRead(50);
    return m_pSerialPort->readAll();
}

