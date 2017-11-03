using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace LogisticDB
{
    /// <summary>
    /// Логика взаимодействия для ReportsWindow.xaml
    /// </summary>
    public partial class ReportsWindow : Window
    {
        LogisticData db;

        ReportsWindow()
        {
            InitializeComponent();
        }

        public static void ShowReportsDialog(LogisticData db)
        {
            var win = new ReportsWindow();
            win.db = db;
            win.ShowDialog();
        }

        private bool CheckInputDates()
        {
            if (FromCalendar.SelectedDate == null)
            {
                MessageBox.Show("Select from date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return false;
            }
            if (ToCalendar.SelectedDate == null)
            {
                MessageBox.Show("Select to date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return false;
            }
            if (FromCalendar.SelectedDate >= ToCalendar.SelectedDate)
            {
                MessageBox.Show("From date must be lesser then to date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return false;
            }
            return true;
        }

        private void StayCoefButton_Click(object sender, RoutedEventArgs e)
        {
            if (!CheckInputDates())
                return;

            ReportDataGrid.ItemsSource = db.GetStayCoefReport(FromCalendar.SelectedDate.Value, ToCalendar.SelectedDate.Value);
        }

        private void PopularCargoesButton_Click(object sender, RoutedEventArgs e)
        {
            ReportDataGrid.ItemsSource = db.GetPopularCargoesReport();
        }

        private void PopularCitiesButton_Click(object sender, RoutedEventArgs e)
        {
            ReportDataGrid.ItemsSource = db.GetPopularCitiesReport();
        }

        private void FinancialReportButton_Click(object sender, RoutedEventArgs e)
        {
            ReportDataGrid.ItemsSource = db.GetFinancialReport();
        }

        private void UselessRunCoefButton_Click(object sender, RoutedEventArgs e)
        {
            ReportDataGrid.ItemsSource = db.GetUselessRunCoefReport();
        }

        private void CheckTimeButton_Click(object sender, RoutedEventArgs e)
        {
            CheckTimeButton.IsEnabled = false;

            var coll = new List<Time>();

            int n, start, i;
            for (i = 0, n = 1000, start = 0; n <= 100000; start = n, n *= 10, i++)
            {
                db.MakeTable(start, n);
                var time = new Time();

                time.RowsInTable = n;
                time.AddOne = db.GetTimeAddOne();
                time.AddGroup = db.GetTimeAddGroup();
                time.AddGroup2 = db.GetTimeAddGroup2();
                time.FindByKey = db.GetTimeFindByKey(n);
                time.FindByString = db.GetTimeFindByString(n);
                time.FindByMask = db.GetTimeFindByMask();
                time.UpdateByKey = db.GetTimeUpdateByKey(n);
                time.UpdateByMask = db.GetTimeUpdateByMask();
                time.DeleteByKey = db.GetTimeDeleteByKey(n);
                time.DeleteByMask = db.GetTimeDeleteByMask();
                time.DeleteGroup = db.GetTimeDeleteGroup(n);
              //  time.Optimize1 = db.GetTimeOptimize1(n);
              //  time.Optimize2 = db.GetTimeOptimize2();

                coll.Add(time);
            }

            ReportDataGrid.ItemsSource = coll;
        }

        private void StayCoefAllButton_Click(object sender, RoutedEventArgs e)
        {
            if (!CheckInputDates())
                return;

            float coef = db.GetStayCoefForAllReport(FromCalendar.SelectedDate.Value, ToCalendar.SelectedDate.Value);
            MessageBox.Show("Stay coefficient for all: " + coef, "", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void UselessRunAllCoefButton_Click(object sender, RoutedEventArgs e)
        {
            ReportDataGrid.ItemsSource = db.GetUselessRunCoefForAllReport();
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}

