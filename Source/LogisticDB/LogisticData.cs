using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Dapper;
using Npgsql;

namespace LogisticDB
{
    public class City
    {
        public int id { get; set; }
        public string name { get; set; }
        public override string ToString()
        {
            return id.ToString() + " " + name;
        }
    }

    public class CargoType
    {
        public int id { get; set; }
        public string name { get; set; }
        public override string ToString()
        {
            return id.ToString() + " " + name;
        }
    }

    public class Car
    {
        public int id { get; set; }
        public string registration_number { get; set; }
        public int carmodel_id { get; set; }

        public override string ToString()
        {
            return id.ToString() + " " + registration_number + " " + carmodel_id;
        }
    }
    
    public class CarModel
    {
        public int id { get; set; }
        public string name { get; set; }
        public int cargotype_id { get; set; }
        public float payload { get; set; }
        public double price_buy { get; set; }
        public double price_sell { get; set; }
        public double price_empty_per_km { get; set; }
        public double price_full_per_km { get; set; }
        public double price_stand_per_day { get; set; }
    }
    
    public class CarView : Car
    {
        public string carmodel_name { get; set; }
        public string cargotype_name { get; set; }
        public int cargotype_id { get; set; }
        public float payload { get; set; }
        public double price_buy { get; set; }
        public double price_sell { get; set; }
        public double price_empty_per_km { get; set; }
        public double price_full_per_km { get; set; }
        public double price_stand_per_day { get; set; }
        public DateTime date_buy { get; set; }
        public DateTime? date_sell { get; set; }
    }
    
    public class CarModelCargoType : CarModel
    {
        public string cargotype_name { get; set; }
    }
    
    public class Transaction
    {
        public int id { get; set; }
        public int car_id { get; set; }
        public float weight { get; set; }
        public int city_from { get; set; }
        public int city_to { get; set; }
        public DateTime date_from { get; set; }
        public DateTime? date_to { get; set; }
    }

    public class CarViewExpense : CarView
    {
        public double expense { get; set; }
    }

    public class TransactionView : Transaction
    {
        public string city_from_name { get; set; }
        public string city_to_name { get; set; }
        public double expense { get; set; }
        public double reward { get; set; }
        public int distance { get; set; }
        public bool isUnprofitable { get { return reward > 0 && expense >= reward; } }
        public bool isProfitable { get { return reward > 0 && expense < reward; } }

    }

    public class CarCoef
    {
        public string registration_number { get; set; }
        public string carmodel_name { get; set; }
        public string cargotype_name { get; set; }
        public float payload { get; set; }
        public float coef { get; set; }
    }

    public class PopularCargoes
    {
       // public int cargotype_id { get; set; } 
        public string cargotype_name { get; set; }
        public float sum_weight { get; set; }
    }

    public class PopularCities
    {
        public string city_from_name { get; set; }
        public float sum_weight { get; set; }
    }

    public class FinancialReport
    {
        public string carmodel_name { get; set; }
        public string cargotype_name { get; set; }
        public string source { get; set; }
        public double expense { get; set; }
        public double reward { get; set; }
   //     public bool isUnprofitable { get { return reward > 0 && expense >= reward; } }
        public bool isProfitable { get { return reward > 0 && expense < reward; } }
        public DateTime date_from { get; set; }
        public DateTime? date_to { get; set; }
    }

    public class PerfomanceTime
    {
        public int RowsInTable { get; set; }
        public double AddOne { get; set; }
        public double AddGroup { get; set; }
        public double FindByKey { get; set; }
        public double FindByString { get; set; }
        public double FindByMask { get; set; }
        public double UpdateByKey { get; set; }
        public double UpdateByString { get; set; }
        public double DeleteByKey { get; set; }
        public double DeleteByString { get; set; }
        public double DeleteGroup { get; set; }
        public double Compress1 { get; set; }
        public double Compress2 { get; set; }
    }
        
    public class LogisticData
    {
        string ConnectStr { get { return "Server=127.0.01;Port=5439;User=postgres;Password=postgres;Database=logistic;CommandTimeout=60"; } }

        public IEnumerable<City> GetCities()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<City>("SELECT * FROM get_cities()");
            }
        }

        public IEnumerable<CarModelCargoType> GetCarModelCargoTypes()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<CarModelCargoType>("SELECT *, get_cargotype_name(m.cargotype_id) as cargotype_name FROM carmodels as m");
            }
        }

        public IEnumerable<CarView> GetCarViews()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<CarView>("SELECT * FROM  cars_view");
            }
        }

        public IEnumerable<CargoType> GetCargoTypes()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<CargoType>("SELECT * FROM  cargotypes");
            }
        }


        public void BuyCar(int city_id, int carModel_id, DateTime date, string number)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                conn.Execute(@"SELECT * FROM  buy_car(@carModel_id, @number, @city_id, ((@date)::date))",
                    new { carModel_id = carModel_id, number = number, city_id = city_id, date = date });
            }
        }

        public void SellCar(CarView car, DateTime date)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                conn.Execute(@"SELECT * FROM  sell_car(@car_id, ((@date)::date))",
                    new { car_id = car.id, date = date });
            }
        }

        public IEnumerable<CarViewExpense> FindCarForTransaction(City city_from, City city_to, DateTime date, CargoType cargoType, float weight)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                var res = conn.Query<CarViewExpense>(@"SELECT * FROM cars_view AS cv INNER JOIN find_cars_for_transaction(@cargotype_id, @weight, @city_id_from , @city_id_to, ((@date)::date)) as f ON f.car_id = cv.id",
                    new { cargotype_id = cargoType.id, weight = weight, city_id_from = city_from.id, city_id_to = city_to.id, date = date }).ToList();
                return res;
            }
        }

        public void MakeTransaction(CarViewExpense car, City city_from, City city_to, DateTime date, float weight)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                conn.Execute(@"SELECT * FROM  make_transaction(@_car_id, @weight, @_city_id_from, @_city_id_to, ((@date)::date))",
                    new { _car_id = car.id, weight = weight, _city_id_from = city_from.id, _city_id_to = city_to.id, date = date });
            }
        }

        public IEnumerable<CarCoef> GetStayCoefReport(DateTime from, DateTime to)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<CarCoef>(@"SELECT * FROM stay_coef_report(@from::date, @to::date) ",
                                           new { from = from, to = to });
            }
        }

        public IEnumerable<CarCoef> GetUselessRunCoefReport(DateTime from, DateTime to)
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<CarCoef>(@"SELECT * FROM useless_run_report(@from::date, @to::date)",
                                           new { from = from, to = to });
            }
        }

        public IEnumerable<PopularCargoes> GetPopularCargoesReport()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<PopularCargoes>("SELECT *, c.name as cargotype_name FROM popular_cargoes() AS p INNER JOIN cargotypes AS c ON p.cargotype_id = c.id");
            }
        }

        public IEnumerable<PopularCities> GetPopularCitiesReport()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<PopularCities>("SELECT *, c.name as city_from_name FROM popular_cities() AS p INNER JOIN cities AS c ON p.city = c.id");
            }
        }

        public IEnumerable<FinancialReport> GetFinancialReport()
        {
            using (NpgsqlConnection conn = new NpgsqlConnection(ConnectStr))
            {
                return conn.Query<FinancialReport>("SELECT * FROM financial_report() as f");
            }
        }

        public void MakeExampleTable(int n)
        {
            int i;
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"CREATE TABLE IF NOT EXISTS example{0} 
                (id serial NOT NULL PRIMARY KEY, name text NOT NULL, type_id
                integer NOT NULL, payload real NOT NULL, price_buy double
                precision NOT NULL, price_sell double precision NOT NULL); ALTER TABLE example{0} SET (autovacuum_enabled = false, toast.autovacuum_enabled = false);", n);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            cmd.ExecuteNonQuery();
            com = String.Format(@"INSERT INTO example{0} (name, type_id, payload, price_buy, price_sell) VALUES ", n);
            for (i = 0; i < n; i++)
                com += String.Format(" ('tmp{0}', 20, 10, 3.5e6, 2.5e5){1}", i, i == n - 1 ? "" : ",");
            cmd = new NpgsqlCommand(com, conn);
            cmd.ExecuteNonQuery();
            conn.Close();
        }

        public void CopyExampleToTestTable(int n)
        {
            int i;
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"DROP TABLE IF EXISTS test{0};
                CREATE TABLE test{0} AS SELECT * FROM example{0}; 
                 ALTER TABLE test{0}
                 ADD CONSTRAINT test{0}_id_pkey PRIMARY KEY (id);
           ", n);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            cmd.ExecuteNonQuery();
            var max = conn.ExecuteScalar<int>("SELECT MAX(id) FROM test" + n.ToString());
            conn.Execute(string.Format(@"CREATE SEQUENCE IF NOT EXISTS test{0}_id_seq START WITH {1};
                                         SELECT setval('test{0}_id_seq',{1}, true); 
                                         ALTER TABLE test{0} ALTER COLUMN id SET DEFAULT nextval('test{0}_id_seq');", n, max));

            conn.Close(); 
        }


        public void DelTestTable(int n)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"DROP TABLE test{0}", n); 
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            cmd.ExecuteNonQuery();
            conn.Close();
        }

        public void DelExampleTable(int n)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"DROP TABLE example{0}", n);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            cmd.ExecuteNonQuery();
            conn.Close();
        }


        public PerfomanceTime GetPerfomanceTime(int n)
        {
            PerfomanceTime time = new PerfomanceTime();
            int i = 0;

            time.RowsInTable = n;
            //var conn = new NpgsqlConnection(ConnectStr);
            //var t = DateTime.Now; 
            //conn.ExecuteScalar<int>("SELECT 1");
            //var delta = DateTime.Now - t;
            //conn.Close();

            MakeExampleTable(n);

            int nTests = 1;
            for (i = 0; i < nTests; i++)
            {
                CopyExampleToTestTable(n);
                int j = i + 1;
                int k = i + 2;
                int m = i + 3;
                time.AddOne += GetTimeAddOne(n);
                time.FindByKey += GetTimeFindByKey(j, n);
                time.UpdateByKey += GetTimeUpdateByKey(k, n);
                time.DeleteByKey += GetTimeDeleteByKey(m, n);
                time.AddGroup += GetTimeAddGroup(n);
                time.FindByString += GetTimeFindByString(n);
                time.FindByMask += GetTimeFindByMask(n);
                time.UpdateByString += GetTimeUpdateByString(n);
                time.DeleteByString += GetTimeDeleteByString(n);
                time.DeleteGroup += GetTimeDeleteGroup(n);
                time.Compress1 += GetTimeVacuum1(n);
                time.Compress2 += GetTimeVacuum2(n);
                DelTestTable(n);
            }
            DelExampleTable(n);

            time.AddOne /= nTests;
            time.AddGroup /= nTests;
            time.FindByKey /= nTests;
            time.FindByString /= nTests;
            time.FindByMask /= nTests;
            time.UpdateByKey /= nTests;
            time.UpdateByString /= nTests;
            time.DeleteByKey /= nTests;
            time.DeleteByString /= nTests;
            time.DeleteGroup /= nTests;

            return time;
        }

        public double GetTimeAddOne(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"INSERT INTO test" + num + "(name, type_id, payload, price_buy, price_sell) VALUES ('new', 20, 10, 3.5e6, 2.5e5)");
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            cmd.ExecuteNonQuery();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeAddGroup(int num)
        {
            int i = 0;
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            string com;
            NpgsqlCommand cmd;
            conn.Open();

            var startTime = DateTime.Now;
            for (i = 0; i < 101; i++)
            {
                com = String.Format(@"INSERT INTO test" + num + "(name, type_id, payload, price_buy, price_sell) VALUES ('new" + i + "', 20, 10, 3.5e6, 2.5e5)");
                cmd = new NpgsqlCommand(com, conn);
                cmd.ExecuteNonQuery();
            }
            double dtime = (DateTime.Now - startTime).TotalSeconds;

            conn.Close();
            return dtime;
        }

        public double GetTimeFindByKey(int i, int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format("SELECT * FROM test" + num + " WHERE id = " + i);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);

            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            var carmodels = new List<CarModel>();
            while (dr.Read())
            {
                carmodels.Add(new CarModel { id = dr.GetInt32(0), name = dr.GetString(1), cargotype_id = dr.GetInt32(2), payload = dr.GetFloat(3), price_buy = dr.GetDouble(4), price_sell = dr.GetDouble(5) });
            }

            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeFindByString(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format("SELECT * FROM test" + num + " WHERE name = 'new'");
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            var carmodels = new List<CarModel>();
            while (dr.Read())
            {
                carmodels.Add(new CarModel { id = dr.GetInt32(0), name = dr.GetString(1), cargotype_id = dr.GetInt32(2), payload = dr.GetFloat(3), price_buy = dr.GetDouble(4), price_sell = dr.GetDouble(5) });
            }
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeFindByMask(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format("SELECT * FROM test" + num + " WHERE name LIKE 'new5%'");
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            var carmodels = new List<CarModel>();
            while (dr.Read())
            {
                carmodels.Add(new CarModel { id = dr.GetInt32(0), name = dr.GetString(1), cargotype_id = dr.GetInt32(2), payload = dr.GetFloat(3), price_buy = dr.GetDouble(4), price_sell = dr.GetDouble(5) });
            }
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeUpdateByKey(int i, int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"UPDATE test" + num + " SET name = 'test', type_id = 2, payload = 5, price_buy = 1e6, price_sell = 2e6 WHERE id = " + i);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeUpdateByString(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format(@"UPDATE test" + num + " SET name = 'test', type_id = 2, payload = 5, price_buy = 1e6, price_sell = 2e6 WHERE name = 'newnTests'");
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeDeleteByKey(int i, int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format("DELETE FROM test" + num + " WHERE id = " + i);
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeDeleteByString(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com = String.Format("DELETE FROM test" + num + " WHERE name = 'newnTests'");
            NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
            var startTime = DateTime.Now;
            NpgsqlDataReader dr = cmd.ExecuteReader();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeDeleteGroup(int num)
        {
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var startTime = DateTime.Now;
            for (int i = 0; i < 100; i++)
            {
                var com = String.Format("DELETE FROM test" + num + " WHERE name LIKE 'new" + i + "'");
                NpgsqlCommand cmd = new NpgsqlCommand(com, conn);
                NpgsqlDataReader dr = cmd.ExecuteReader();
            }
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            conn.Close();
            return dtime;
        }

        public double GetTimeVacuum1(int num)
        {
            int tmp = num - 200;
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com1 = String.Format("DELETE FROM test" + num + " WHERE id >= " + tmp);
            var com2 = String.Format("VACUUM test" + num + "");
            NpgsqlCommand cmd = new NpgsqlCommand(com1, conn);
            cmd.ExecuteNonQuery();
            var startTime = DateTime.Now;
            cmd = new NpgsqlCommand(com2, conn);
            cmd.ExecuteNonQuery();
            conn.Close();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            return dtime;
        }

        public double GetTimeVacuum2(int num)
        {
            int tmp = num - 200;
            var startTime = DateTime.Now;
            NpgsqlConnection conn = new NpgsqlConnection(ConnectStr);
            conn.Open();
            var com1 = String.Format("DELETE FROM  test" + num + " WHERE id <= " + tmp);
            var com2 = String.Format("VACUUM test" + num);
            NpgsqlCommand cmd = new NpgsqlCommand(com1, conn);
            NpgsqlDataReader dr = cmd.ExecuteReader();
            cmd = new NpgsqlCommand(com2, conn);
            dr = cmd.ExecuteReader();
            conn.Close();
            double dtime = (DateTime.Now - startTime).TotalSeconds;
            return dtime;
        }
    }
}
