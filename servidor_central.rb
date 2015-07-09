#Servidor central e de consulta de banco de dados 
#Autores: Jesue, Lidio, Joalison

#Requerindo socket e driver de compatibilidade com sqlite3
require 'socket'
require 'rdbi-driver-sqlite3'
 
 #definindo Protocolo a ser utilizado
 #UTP na porta 2100 
 #Conexão com banco servidor_dominio
socket = UDPSocket.new
socket.bind("", 2100)
dbh = RDBI.connect(:SQLite3, :database => "servidor_dominio.db")
aspas = '"'
reply = nil
loop {
  puts "Conectado"
  s, sender = socket.recvfrom(1024)
  puts s
  #Colocando dentro de um array amrequisição
  #cliente IP irá receber IP e cliente porta ira receber a porta e comando
  solicitacao = s.split
  cliente_ip = sender[3]
  cliente_port = sender[1]
  if solicitacao[0] == "REG"
    if solicitacao[1] != nil && solicitacao[2] != nil
      begin
        puts "RECEBENDO SOLICITACAO DE REGISTRO DE DOMINIO"
#Inserindo Dados nas tabelas/colunas do banco
#e aviso de falhas		
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