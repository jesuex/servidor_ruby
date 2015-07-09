#Código de um servidor central para inserção de servidores locais.
#Registro de servidores apenas com Domínio e IP


#Solicitação de uso de socket
require 'socket'
require 'rdbi-driver-sqlite3'

#Ultilizando protocolo UDP para abrir uma porta ou conexão 
socket = UDPSocket.new
socket.bind("", 2100)

#chamando bibliotecas para conxão com banco de dados
dbh = RDBI.connect(:SQLite3, :database => "servidor_dominio.db")
aspas = '"'
reply = nil
loop {
  puts "Conectado"
  s, sender = socket.recvfrom(1024)
  puts s

#Tratando a solicitação, onde a solicitação [0] ficara com a mensagem REG, solicitação [1] ficará com o nome de domínio
#e solicitação [2] ficará com o endereço de IP
  solicitacao = s.split
  cliente_ip = sender[3]
  cliente_port = sender[1]
  if solicitacao[0] == "REG"
    if solicitacao[1] != nil && solicitacao[2] != nil
      begin
        puts "RECEBENDO SOLICITACAO DE REGISTRO DE DOMINIO"

#Chamando comando SQL para cadastrar servidores.    
    dbh.execute("insert into servidores (dominio, ip) values ( \"#{solicitacao[1]}\", \"#{solicitacao[2]}\")")
    puts " Registro Realizado com Sucesso!"
    socket.send "REGOK", 0 , cliente_ip, cliente_port
      rescue
        puts "O Dominio ja esta registrado"
    socket.send "REGFALHA", 0, cliente_ip, cliente_port
      end
    else
      puts " Falha Inesperada "
      socket.send "FALHA", 0, cliente_ip, cliente_port
    end
  elsif solicitacao[0] == "IP"
    if solicitacao[1] != nil
      puts "Recebendo IP!"
      rs = dbh.execute("select * from servidores where dominio = \"#{solicitacao[1]}\"")
      rs.fetch(:all).each do |row|
      reply = row
    end
    if reply != nil
      puts "Enviando IP"
      socket.send "IPOK #{reply}", 0, cliente_ip, cliente_port
    elsif reply == nil
      puts "Endereco IP nao encontrado"
      socket.send "IPFALHA", 0, cliente_ip, cliente_port
    end
    else
      puts "Falha Inesperada!"
      socket.send "FALHA", 0, cliente_ip, cliente_port
    end
  else
    puts "Falha Inesperada!"
    socket.send "FALHA", 0, cliente_ip, cliente_port    
  end
}
socket.close
