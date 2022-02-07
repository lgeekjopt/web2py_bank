##### https://pynative.com/python-mysql-transaction-management-using-commit-rollback/
##### https://stackoverflow.com/questions/12867140/python-mysqldb-get-the-result-of-fetchall-in-a-list/12867429
##### https://www.geeksforgeeks.org/how-to-print-out-all-rows-of-a-mysql-table-in-python/
####

import MySQLdb as mdb
import hashlib
#### funcoes MySQL
''' criarUser(nome,username,password) done
    efetuarDeposito(id,valordepositar) done
    efetuarLevantamento(id,valorlevantar) done
    efetuarTransferencia(id,iduserDestino,valor) done
    efetuarTransferenciaInterna(id, 'ordem', 'prazo', valor)
    mostrarMovimentos(id,NULL) ou deposito/debitar/creditar/levantamento done
    mostrarSaldo(1,NULL) ou ordem/prazo done
    mostrarTransferencias(ID,NULL) ou externa/interna done
    mostrarUtilizadores(); done
    autenticaUtilizador(user,pass) done
'''

####

def criarUser(nome, utilizador,password):
    password = hashlib.sha224(password.encode('ascii')).hexdigest()
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    #cur.execute("call inserirUtilizador('"+utilizador+"','"+password+"');")
    if utilizador and password and nome: 
        print("call criarUser('"+nome+"','"+utilizador+"','"+password+"');")

        cur.execute("call criarUser('"+nome+"','"+utilizador+"','"+password+"');") #concatenar as variaveis a query inserirUtilizador
        result=cur.fetchall()
        
        print("affected rows = {}".format(cur.rowcount)) #rowcount, leitura das rows que ocorreu alteracoes, no caso inserir
        if result:
            return utilizador
        else: 
            con.commit() #efectuar alteracoes na base de dados
            return 1 
    if con:
        con.close()
    #result = cur.fetchall()
    
def mostrarNome(id):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id: 
        print("select nome from users where id="+str(id)+";")
        cur.execute("select nome from users where id="+str(id)+";")
        result=cur.fetchall()
    if result:
        for row in result:
            print(str(row[0]))
            return str(row[0]) ####### return so nome
    if con:
        con.close()

def efetuarDeposito(id,valordepositar):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and valordepositar: 
        print("call efetuarDeposito("+str(id)+","+str(valordepositar)+");")
        cur.execute("call efetuarDeposito("+str(id)+","+str(valordepositar)+");")
        con.commit() #efetuar alteracoes base de dados
    if con:
        con.close()

def mostrarUtilizadores(id):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    linhas = cur.execute("call mostrarUtilizadores("+str(id)+");")
    result = cur.fetchall()
    #result = cur.fetchone()
    #print("Estes foram os utilizadores que encontrei na base de dados\n")
    if result:
        string="<table class='table table-sm table-bordered'><thead><tr>"
        ##vou buscar as colunas do mysql query
        num_fields = len(cur.description)
        field_names = [i[0] for i in cur.description]
        ##primeira linha da coluna a indicar o cabecalho
        for i in field_names:
            string+="<th scope='col'>"+i+"</th>"
            print(i)
        string+="</tr></thead><tbody>"
        ##percorrer o resultado
        for rows in result:
            string+="<tr>"
            for row in rows:
                string+="<td>"+str(row)+"</td>"
                print(str(row))
            string+="</tr>"
        string+="</tbody></table>"
        return string
    if con:
        con.close()

def autenticaUtilizador(utilizador,password):
    password = hashlib.sha224(password.encode('ascii')).hexdigest()
    #print(utilizador,password)
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    print("call autenticaUtilizador('"+utilizador+"','"+password+"');")
    cur.execute("call autenticaUtilizador('"+utilizador+"','"+password+"');")
    result = cur.fetchall()
    if result:
        for row in result:
            return row[0],row[1] #retornar o ID do utilizador e nome
    else:
        return 0, 0 
    if con:
        con.close()


##returns nothing on mysql se sucessido
##se falhar retorna string "Nao tens saldo suficiente"
def efetuarLevantamento(id,valorlevantar):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and valorlevantar: 
        print("call efetuarLevantamento("+str(id)+","+str(valorlevantar)+");")
        cur.execute("call efetuarLevantamento("+str(id)+","+str(valorlevantar)+");")
        result=cur.fetchall()
    
    if result: ## failed
        for row in result: 
            print(row[0]) #Nao tens saldo suficiente
            return row[0]
    else: 
        con.commit() #efetuar alteracoes base de dados
        print("levantamento de "+str(valorlevantar)+ " de user ID "+str(id)+ " com sucesso")
        return 1

    if con:
        con.close()

##can receive null
##retorna tabela com os movimentos
##por padrao os ultimos 10
def mostrarMovimentos(id,tipo):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and tipo: 
        print("call mostrarMovimentos("+str(id)+",'"+str(tipo)+"');")
        if tipo == "NULL": 
            cur.execute("call mostrarMovimentos("+str(id)+","+str(tipo)+");")
        else:
            cur.execute("call mostrarMovimentos("+str(id)+",'"+str(tipo)+"');")
        result=cur.fetchmany(size=10)
        print(result)
    if result:
        string="<table class='table table-sm table-bordered'><thead><tr>"
        ##vou buscar as colunas do mysql query
        num_fields = len(cur.description)
        field_names = [i[0] for i in cur.description]
        ##primeira linha da coluna a indicar o cabecalho
        for i in field_names:
            string+="<th scope='col'>"+i+"</th>"
            print(i)
        string+="</tr></thead><tbody>"
        ##percorrer o resultado
        for rows in result:
            string+="<tr>"
            for row in rows:
                string+="<td>"+str(row)+"</td>"
                print(str(row))
            string+="</tr>"
        string+="</tbody></table>"
        return string

    if con:
        con.close()

    

#can receive null
#return so saldo
def mostrarSaldo(id,tipo):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and tipo: 
        print("call mostrarSaldo("+str(id)+",'"+str(tipo)+"');")
        if tipo == "NULL": 
            cur.execute("call mostrarSaldo("+str(id)+","+str(tipo)+");")
        else:
            cur.execute("call mostrarSaldo("+str(id)+",'"+str(tipo)+"');")
        result=cur.fetchall()
    if result:
        for row in result:
            print(str(row[0]))
            return str(row[0]) ####### return so saldo
    if con:
        con.close()

#can receive null
def mostrarTransferencias(id,tipo):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and tipo: 
        print("call mostrarTransferencias("+str(id)+",'"+str(tipo)+"');")
        if tipo == "NULL": 
            cur.execute("call mostrarTransferencias("+str(id)+","+str(tipo)+");")
        else:
            cur.execute("call mostrarTransferencias("+str(id)+",'"+str(tipo)+"');")
        result=cur.fetchmany(size=10)
        #result=cur.fetchall()
    if result:
        string="<table class='table table-sm table-bordered'><thead><tr>"
        ##vou buscar as colunas do mysql query
        num_fields = len(cur.description)
        field_names = [i[0] for i in cur.description]
        ##primeira linha da coluna a indicar o cabecalho
        for i in field_names:
            string+="<th scope='col'>"+i+"</th>"
            print(i)
        string+="</tr></thead><tbody>"
        ##percorrer o resultado
        for rows in result:
            string+="<tr>"
            for row in rows:
                string+="<td>"+str(row)+"</td>"
                print(str(row))
            string+="</tr>"
        string+="</tbody></table>"
        return string
    else: 
        return "<b>Nenhuma transferencia efetuada</b>"

    if con:
        con.close()

    

##returns nothing on mysql se sucessido
##returns 1 row is failed
def efetuarTransferencia(idOrigem,idDestino,valor):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if idOrigem and idDestino and valor: 
        print("call efetuarTransferencia("+str(idOrigem)+","+str(idDestino)+","+str(valor)+");")
        cur.execute("call efetuarTransferencia("+str(idOrigem)+","+str(idDestino)+","+str(valor)+");")
        result=cur.fetchall()
    if result: ## failed
        for rows in result:
            for row in rows:
                print(str(row))
                return str(row)
    else: 
        con.commit()
        print("Transferencia de "+str(valor)+ " de ID "+str(idOrigem)+" para "+str(idDestino)+ " com sucesso")
        return 1

    if con:
        con.close()

#returns nothing on mysql se sucessido
##returns 1 row if failed
def efetuarTransferenciaInterna(id,origem,destino,valor):
    con = mdb.connect('localhost','pythontest','0myg0d!','projeto_distribuidos')
    cur = con.cursor()
    if id and origem and destino and valor:
        if origem != destino:
            print("call efetuarTransferenciaInterna("+str(id)+",'"+str(origem)+"','"+str(destino)+"',"+str(valor)+");")
            cur.execute("call efetuarTransferenciaInterna("+str(id)+",'"+str(origem)+"','"+str(destino)+"',"+str(valor)+");")
            result=cur.fetchall()
    if result: ## failed
        for rows in result:
            for row in rows:
                print(str(row))
                return str(row)
    else: 
        con.commit()
        print("Transferencia interna de "+str(valor)+ " UserID "+str(id)+" de "+origem+" para "+destino+" com sucesso")
        return 1

    if con:
        con.close()
