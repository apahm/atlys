/*

Copyright (c) 2021 Alex Pahmutov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

#include <iostream>

#include "uart.h"
#define DEBUG

Uart::Uart()
{
    // Инициализация последовательного порта.
    m_pSerialPort = new QSerialPort();
    m_pSerialPort->setPortName("/dev/ttyXRUSB0");
    
    m_pSerialPort->setBaudRate(QSerialPort::Baud115200);
    m_pSerialPort->setDataBits(QSerialPort::Data8);
    m_pSerialPort->setParity(QSerialPort::NoParity);
    m_pSerialPort->setStopBits(QSerialPort::OneStop);
    m_pSerialPort->setFlowControl(QSerialPort::NoFlowControl);
    
    connect();
}

Uart::~Uart()
{
    delete m_pSerialPort;
}
 
bool Uart::is_connected() const
{
    return m_isConnected;
}
 
void Uart::connect()
{
    if (m_pSerialPort->open(QSerialPort::ReadWrite))
    {
        m_isConnected = true;
#ifdef DEBUG
        std::cout << "Connect to fpga successful!" << std::endl;
#endif
    }
    else
        m_isConnected = false;
}
 
QByteArray Uart::test_uart()
{
    QByteArray sentData;
    sentData.resize(6);
    sentData[0] = STARTBYTE;
    sentData[1] = DEV;
    sentData[2] = 0x2f;
    sentData[3] = 0x7a;
    sentData[4] = 0x8b;
    sentData[5] = 0xd9;

 
    int ret = m_pSerialPort->write(sentData);
    if(ret != 6)
    {
        std::cout << "Write error!" << std::endl;
    }
    m_pSerialPort->waitForBytesWritten(100);

    m_pSerialPort->waitForReadyRead(50);
    const QByteArray data = m_pSerialPort->readAll();

    if (( (0xFF & data.at(0)) == STARTBYTE) 
     && ( (0xFF & data.at(1)) == DEV) 
     && ( (0xFF & data.at(2)) == 0x2f) 
     && ( (0xFF & data.at(3)) == 0x7a) 
     && ( (0xFF & data.at(4)) == 0x8b) 
     && ( (0xFF & data.at(5)) == 0xd9))
    {
        std::cout << "Test successful!" << std::endl;
    }

    return 0;
}

int Uart::start_write_frame()
{
    QByteArray sentData;
    sentData.resize(1);
    sentData[0] = 0xFF;
    int ret = m_pSerialPort->write(sentData);
    m_pSerialPort->waitForBytesWritten(100);
    return ret;
}