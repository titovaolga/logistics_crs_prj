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
    /// Логика взаимодействия для SellCarWindow.xaml
    /// </summary>
    public partial class SellCarWindow : Window
    {
        LogisticData db;

        public SellCarWindow()
        {
            InitializeComponent();
        }

        public static void ShowSellCarDialog(LogisticData db)
        {
            var win = new SellCarWindow();
            win.db = db;
            win.CarsListView.ItemsSource = db.GetCarViews();
            win.ShowDialog();
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            if (CarsListView.SelectedItem == null)
            {
                MessageBox.Show("Please, select car from the list above!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            if ((DateTime)DateCalender.SelectedDate == null)
            {
                MessageBox.Show("Select date!", "", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            db.SellCar(CarsListView.SelectedItem as CarView,
                   (DateTime)DateCalender.SelectedDate);
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
