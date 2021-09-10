#ifndef EMITTER_H
#define EMITTER_H
 
#include <QSerialPort>
 
class Uart
{
public:
    Uart();
    ~Uart();

    bool is_connected() const;
    void connect();

    QByteArray test_uart();

private:
    const quint8 STARTBYTE = 0x40; 
    const quint8 DEV = 0x10;  
 
    QSerialPort *m_pSerialPort;
    bool m_isConnected;
};
 
#endif // EMITTER_H