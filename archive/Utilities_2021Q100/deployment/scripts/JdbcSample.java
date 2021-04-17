/**
 * Copyright (c) 2014
 * Cisco Systems, Inc.
 * All Rights Reserved
 */

import java.sql.*;
import java.text.SimpleDateFormat;

class JdbcSample
{
    public static void main(String args[]) 
    {
        if (args.length != 7 && args.length != 8) {
            System.err.println("usage : prog <datasource name> <host name> <port> <user> <password> <domain name> \"<sql statement>\" [-fileEncoding <value>]");
            System.err.println("        prog <datasource name> <host name> <port> <user> <password> <domain name> \"<sql statement>\" -encrypt [-fileEncoding <value>]");
            System.exit(1);
        }

        String datasource = args[0]; // datasource_name
        String ip = args[1]; // IP or host name of Composite Server

        // port of Composite Server dbapi service
        int port = 0;
        try {
            port = Integer.parseInt(args[2]);
        } catch (Exception e) {
            if (args.length == 8) {
                // -encrypt chosen, use default JDBC SSL port
                port = 9403; 
            } else {
                // use default JDBC port
                port = 9401; 
            }
        }

        String userName = args[3];
        String password = args[4];
        String domain = args[5];
        String url = null;

        Connection conn = null;
        Statement stmt = null;  
        ResultSet rs = null;
        ResultSetMetaData rsmd = null;

        try {
            Class.forName("cs.jdbc.driver.CompositeDriver");

            url = "jdbc:compositesw:dbapi@" + ip + ":" + port + "?domain=" +
                domain + "&dataSource=" + datasource;
            if (args.length == 8) {
                url += "&encrypt=true";
            }
            conn = DriverManager.getConnection(url, userName, password);
            stmt = conn.createStatement();
            boolean isNotUpdate = stmt.execute(args[6]);
            int rows = 0;

            // return type is a result set
            if (isNotUpdate == true) {
                rs = stmt.getResultSet();

                if (rs == null) {
                    throw new SQLException("sql=`"+args[6]+"` did not generate a result set");
                }
                rsmd = rs.getMetaData();
          
                int columns = rsmd.getColumnCount();
                System.out.println("column count = " + columns);

                rows = 1;
                int type = 0;
              
                while (rs.next()) {
                    System.out.print("row = `" + rows + "`  ");
                    for (int i=1; i <= columns; i++) {
                        type = rsmd.getColumnType(i);
						Object o = null;
                        rs.getObject(i);
                        if (rs.wasNull()) {
                            System.out.print(" col[" + i + "]=null");
                            continue;
                        }
                        switch (type) {
                            case Types.INTEGER:
                                System.out.print(" col[" + i + "]=`" + rs.getInt(i) + "` ");
                                break;

                            case Types.SMALLINT:
                                System.out.print(" col[" + i + "]=`" + rs.getShort(i) + "` ");
                                break;

                            case Types.TINYINT:
                                System.out.print(" col[" + i + "]=`" + rs.getByte(i) + "` ");
                                break;

                            case Types.BIGINT:
                                System.out.print(" col[" + i + "]=`" + rs.getLong(i) + "` ");
                                break;

                            case Types.FLOAT:
                                System.out.print(" col[" + i + "]=`" + rs.getFloat(i) + "` ");
                                break;

                            case Types.REAL:
                                System.out.print(" col[" + i + "]=`" + rs.getFloat(i) + "` ");
                                break;

                            case Types.DECIMAL:
                                System.out.print(" col[" + i + "]=`" + rs.getBigDecimal(i).toPlainString() + "` ");
                                break;

                            case Types.DOUBLE:
                                System.out.print(" col[" + i + "]=`" + rs.getDouble(i) + "` ");
                                break;

                            case Types.NUMERIC:
                                System.out.print(" col[" + i + "]=`" + rs.getFloat(i) + "` ");
                                break;

                            case Types.CHAR:
                                System.out.print(" col[" + i + "]=`" + rs.getString(i) + "` ");
                                break;

                            case Types.VARCHAR:
                                System.out.print(" col[" + i + "]=`" + rs.getString(i) + "` ");
                                break;

                            case Types.LONGVARCHAR:
                                System.out.print(" col[" + i + "]=`" + rs.getString(i) + "` ");
                                break;

                            case Types.DATE:
                                System.out.print(" col[" + i + "]=`" + rs.getDate(i) + "` ");
                                break;

                            case Types.TIME:
                                System.out.print(" col[" + i + "]=`" + new SimpleDateFormat("HH:mm:ss.SSS").format((Time) rs.getTime(i)) + "` ");
                                break;

                            case Types.TIMESTAMP:
                                System.out.print(" col[" + i + "]=`" + rs.getTimestamp(i) + "` ");
                                break;

                            case Types.BOOLEAN:
                                System.out.print(" col[" + i + "]=`" + rs.getBoolean(i) + "` ");
                                break;

                            default:
                                System.out.print(" col[" + i + "]=`" + rs.getString(i) + "` ");
                                break;
                        }
                    }

                    System.out.println("\n");
                    rows++;
                }

                rs.close();
            } else {
              // return type is not a result set
              rows = stmt.getUpdateCount();
              System.out.println("sql=`"+args[6]+"` affected " + rows + " row(s)");
            }
      
            stmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            if (rs != null)   {
                try {
                    rs.close(); 
                } catch (SQLException ignore) { }
            }
            if (stmt != null) {
                try {
                    stmt.close(); 
                } catch (SQLException ignore) { }
            }
            if (conn != null) {
                try {
                    conn.close(); 
                } catch (SQLException ignore) { }
            }
			System.exit(1);
        } finally {
            rs = null;
            stmt = null;
            conn = null;
        }
    }
}
