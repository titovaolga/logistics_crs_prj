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
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace LogisticDB
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        LogisticData db;
        
        public MainWindow()
        {
            InitializeComponent();
            db = new LogisticData();
            CarsListView.ItemsSource = db.GetCarViews();
        }
        
        private void BuyCarButton_Click(object sender, RoutedEventArgs e)
        {
            BuyCarWindow.ShowBuyDialog(db);
            CarsListView.ItemsSource = db.GetCarViews();
        }

        private void MakeOrderButton_Click(object sender, RoutedEventArgs e)
        {
            MakeOrderWindow.ShowMakeOrderDialog(db);
        }

        private void SellCarButton_Click(object sender, RoutedEventArgs e)
        {
            SellCarWindow.ShowSellCarDialog(db);
            CarsListView.ItemsSource = db.GetCarViews();

        }
    }
}








