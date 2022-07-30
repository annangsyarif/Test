import pandas
from pyhocon import ConfigFactory
from datetime import datetime, timedelta
from sqlalchemy import create_engine

class sql:
  def createConnection(host, port, user, password, database):
    mydb = create_engine(f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}")
    return mydb

  def createTable(dbConn, TableName):
    dbConn.execute(
      f"""create table if not exists {TableName}(
        id INT auto_increment,
        customer_id int not null,
        order_id varchar(255) not null,
        transaction_date timestamp,
        status varchar(255),
        vendor varchar(255),
        ingestion_time timestamp,
        primary key (id)
      )"""
    )

class common:
  def getStartEndDate(confFile):
    try:
      startDate = confFile.get("option.startDate")
      endDate = confFile.get("option.endDate")
    except:
      endDate = datetime.now().date()
      startDate = endDate - timedelta(days=int(confFile.get("option.interval")))
      endDate = str(endDate)
      startDate = str(startDate)
    return(startDate, endDate)


if __name__ == "__main__":
  confFile = ConfigFactory.parse_file("application.conf")
  sourceConn = sql.createConnection(
    confFile.get("mysqlSource.host"),
    confFile.get("mysqlSource.port"),
    confFile.get("mysqlSource.user"),
    confFile.get("mysqlSource.password"),
    confFile.get("mysqlSource.dbName")
  )

  warehouseConn = sql.createConnection(
    confFile.get("mysqlWarehouse.host"),
    confFile.get("mysqlWarehouse.port"),
    confFile.get("mysqlWarehouse.user"),
    confFile.get("mysqlWarehouse.password"),
    confFile.get("mysqlWarehouse.dbName")
  )

  (startDate, endDate) = common.getStartEndDate(confFile)

  df = pandas.read_sql(
    f"""
      Select * from {confFile.get("mysqlSource.tableName")}
      where date(transaction_date) >= {startDate} and date(transaction_date) < {endDate}
    """,
    sourceConn)
  df["ingestion_time"] = datetime.now()
  df = df.set_index("id")
  sql.createTable(warehouseConn, confFile.get("mysqlWarehouse.tableName"))
  df.to_sql(confFile.get("mysqlWarehouse.tableName"), con = warehouseConn, if_exists = 'replace')
  