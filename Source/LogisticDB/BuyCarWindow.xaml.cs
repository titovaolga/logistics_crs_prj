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
    /// Логика взаимодействия для BuyCarWindow.xaml
    /// </summary>
    public partial class BuyCarWindow : Window
    {
        LogisticData db;
        BuyCarWindow()
        {
            InitializeComponent();
        }

        public static void ShowBuyDialog(LogisticData db)
        {
            var win = new BuyCarWindow();
            win.db = db;
            win.CitiesComboBox.ItemsSource = db.GetCities();
            win.ModelsListView.ItemsSource = db.GetCarModelCargoTypes();
            win.ShowDialog();
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            double cost = 0;
            if (CitiesComboBox.SelectedItem == null)
            {
                MessageBox.Show("Select city!", "", MessageBoxButton.OK, MessageBoxImage.Error); //change
                return;
            }
            if (ModelsListView.SelectedItem == null)
            {
                MessageBox.Show("Select model!", "", MessageBoxButton.OK, MessageBoxImage.Error); //change
                return;
            }
            if(string.IsNullOrWhiteSpace(NumberTextBox.Text)) 
            {
                MessageBox.Show("Input number!", "", MessageBoxButton.OK, MessageBoxImage.Error); //change
                return;
            }
                db.BuyCar((CitiesComboBox.SelectedItem as City).id, 
                    (ModelsListView.SelectedItem as CarModelCargoType).id, 
                    DateCalender.DisplayDate, NumberTextBox.Text);
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            Close();
        }
    }
}
