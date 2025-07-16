package com.example.clover_test

import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.accounts.Account;
import android.os.AsyncTask;
import android.os.RemoteException;
import android.os.Bundle;
import android.widget.TextView;
import android.util.Log

import com.clover.sdk.util.CloverAccount;
import com.clover.sdk.v1.BindingException;
import com.clover.sdk.v1.ClientException;
import com.clover.sdk.v1.ServiceException;
import com.clover.sdk.v3.inventory.InventoryConnector;
import com.clover.sdk.v3.inventory.Item;
import com.clover.sdk.v3.inventory.InventoryContract;

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tuapp.clover"
    private val TAG = "CloverIntegration"
    private var isInitialized = false
    private var mAccount: Account? = null
    private var mInventoryConnector: InventoryConnector? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configurando Flutter Engine")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Método llamado: ${call.method}")
            when (call.method) {
                "initialize" -> {
                    Log.i(TAG, "Inicializando conexión con Clover")
                    initializeClover(result)
                }
                "makePayment" -> {
                    if (!isInitialized) {
                        Log.e(TAG, "Intento de pago sin inicialización previa")
                        result.error("NOT_INITIALIZED", "Clover not initialized", null)
                        return@setMethodCallHandler
                    }
                    
                    val amount = call.argument<Int>("amount")
                    if (amount != null) {
                        Log.i(TAG, "Procesando pago por cantidad: $amount")
                        processPayment(amount, result)
                    } else {
                        Log.e(TAG, "Falta parámetro 'amount' en makePayment")
                        result.error("INVALID_ARGUMENT", "Amount is missing", null)
                    }
                }
                "disconnect" -> {
                    Log.i(TAG, "Desconectando de Clover")
                    disconnect(result)
                }
                else -> {
                    Log.w(TAG, "Método no implementado: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializeClover(result: MethodChannel.Result) {
        Thread {
            try {
                Log.d(TAG, "Obteniendo cuenta Clover")
                mAccount = CloverAccount.getAccount(this)
                
                if (mAccount == null) {
                    Log.e(TAG, "No se encontró cuenta Clover")
                    result.error("NO_ACCOUNT", "No Clover account found", null)
                    return@Thread
                }
                
                Log.d(TAG, "Creando InventoryConnector")
                mInventoryConnector = InventoryConnector(this, mAccount!!, null).apply {
                    Log.d(TAG, "Conectando InventoryConnector")
                    connect()
                    isInitialized = true
                    Log.i(TAG, "Conexión con Clover establecida correctamente")
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error al inicializar Clover: ${e.message}", e)
                result.error("INIT_ERROR", e.message, null)
            }
        }.start()
    }

    private fun processPayment(amount: Int, result: MethodChannel.Result) {
        // Simular procesamiento de pago
        Thread {
            Thread.sleep(3000) // Simular tiempo de transacción
            
            runOnUiThread {
                if (Math.random() > 0.1) { // 90% de éxito para simular
                    val transactionId = "CLV-${System.currentTimeMillis()}"
                    Toast.makeText(this, "Pago exitoso: $${amount/100.0}", Toast.LENGTH_SHORT).show()
                    result.success(transactionId)
                } else {
                    // 10% de fallo para pruebas
                    result.error("PAYMENT_FAILED", "El pago fue rechazado", null)
                }
            }
        }.start()
    }

    private fun disconnect(result: MethodChannel.Result) {
        Thread {
            try {
                Log.d(TAG, "Desconectando InventoryConnector")
                mInventoryConnector?.let {
                    it.disconnect()
                    mInventoryConnector = null
                    isInitialized = false
                    Log.i(TAG, "Desconexión completada")
                    result.success(true)
                } ?: run {
                    Log.w(TAG, "No hay conexión activa para desconectar")
                    result.success(false)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error al desconectar: ${e.message}", e)
                result.error("DISCONNECT_ERROR", e.message, null)
            }
        }.start()
    }
}