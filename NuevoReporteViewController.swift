import UIKit
import PhotosUI

// =====================================================================
//  SMSeguro — Pantalla "Nuevo Reporte"
//
//  Se encarga de dos cosas:
//    1. El selector de Categoría (lista desplegable)
//    2. La foto de evidencia (cámara o galería)
//
//  IMPORTANTE: la cámara NO funciona en el simulador, solo en un
//  iPhone real. En el simulador usa "Elegir de la galería".
// =====================================================================

final class NuevoReporteViewController: UIViewController {

    // MARK: - Conexiones al Storyboard

    /// Botón "Selecciona una opción"
    @IBOutlet weak var botonCategoria: UIButton!

    /// Botón grande "Toma foto o sube imagen"
    @IBOutlet weak var botonFoto: UIButton!
    @IBAction func cerrarPantalla(_ sender: Any) {
            dismiss(animated: true)
        }

    // MARK: - Configuración

    private let categorias = [
        "Hoteles y viajes",
        "Electrónicos",
        "Empleos",
        "Vehículos",
        "Boletos para eventos"
    ]

    private let alturaOpcion: CGFloat = 44
    private let tamañoLetra: CGFloat = 16
    private let colorFondoOpcion = UIColor(red: 0.91, green: 0.91, blue: 0.92, alpha: 1)

    // MARK: - Estado

    private var botonesOpcion: [UIButton] = []
    private var desplegado = false

    /// Lo que el usuario eligió. Úsalos cuando guardes el reporte.
    private(set) var categoriaSeleccionada: String?
    private(set) var fotoSeleccionada: UIImage?

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        prepararSelector()
        prepararBotonFoto()
    }


    // =================================================================
    //  MARK: - Selector de categoría
    // =================================================================

    private func prepararSelector() {
        guard let stack = botonCategoria.superview as? UIStackView,
              let indice = stack.arrangedSubviews.firstIndex(of: botonCategoria)
        else {
            print("⚠️ El botón de categoría no está dentro de un Stack View.")
            return
        }

        botonCategoria.addTarget(self, action: #selector(alternarLista),
                                 for: .touchUpInside)

        for (i, nombre) in categorias.enumerated() {
            let opcion = crearOpcion(titulo: nombre)
            opcion.tag = i
            opcion.addTarget(self, action: #selector(elegirCategoria(_:)),
                             for: .touchUpInside)
            opcion.isHidden = true
            opcion.alpha = 0

            botonesOpcion.append(opcion)
            stack.insertArrangedSubview(opcion, at: indice + 1 + i)
        }
    }

    private func crearOpcion(titulo: String) -> UIButton {
        let boton = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = titulo
        config.baseBackgroundColor = colorFondoOpcion
        config.baseForegroundColor = .black
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { [weak self] entrada in
                var salida = entrada
                salida.font = .systemFont(ofSize: self?.tamañoLetra ?? 16)
                return salida
            }
        boton.configuration = config

        boton.heightAnchor.constraint(equalToConstant: alturaOpcion).isActive = true
        return boton
    }

    @objc private func alternarLista() {
        desplegado.toggle()
        animarOpciones(visibles: desplegado)
    }

    @objc private func elegirCategoria(_ boton: UIButton) {
        let elegida = categorias[boton.tag]
        categoriaSeleccionada = elegida
        ponerTitulo(elegida, en: botonCategoria, color: .black)

        desplegado = false
        animarOpciones(visibles: false)
    }

    private func animarOpciones(visibles: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.botonesOpcion.forEach {
                $0.isHidden = !visibles
                $0.alpha = visibles ? 1 : 0
            }
            self.view.layoutIfNeeded()
        }
    }


    // =================================================================
    //  MARK: - Foto de evidencia
    // =================================================================

    private func prepararBotonFoto() {
        botonFoto.addTarget(self, action: #selector(tocarFoto), for: .touchUpInside)
        // La foto se recorta para llenar el recuadro sin deformarse.
        botonFoto.configuration?.background.imageContentMode = .scaleAspectFill
        botonFoto.clipsToBounds = true
    }

    @objc private func tocarFoto() {
        let hoja = UIAlertController(title: "Foto de evidencia",
                                     message: nil,
                                     preferredStyle: .actionSheet)

        // La cámara solo existe en dispositivos reales.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            hoja.addAction(UIAlertAction(title: "Tomar foto", style: .default) { [weak self] _ in
                self?.abrirCamara()
            })
        }

        hoja.addAction(UIAlertAction(title: "Elegir de la galería", style: .default) { [weak self] _ in
            self?.abrirGaleria()
        })

        if fotoSeleccionada != nil {
            hoja.addAction(UIAlertAction(title: "Quitar foto", style: .destructive) { [weak self] _ in
                self?.mostrarFoto(nil)
            })
        }

        hoja.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Necesario para que no truene en iPad.
        hoja.popoverPresentationController?.sourceView = botonFoto
        hoja.popoverPresentationController?.sourceRect = botonFoto.bounds

        present(hoja, animated: true)
    }

    private func abrirCamara() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func abrirGaleria() {
        // PHPickerViewController es el selector moderno: no pide permisos
        // y el usuario solo comparte la foto que elige.
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Pasa `nil` para volver al estado inicial.
    private func mostrarFoto(_ imagen: UIImage?) {
        fotoSeleccionada = imagen

        if let imagen {
            botonFoto.configuration?.background.image = imagen
            botonFoto.configuration?.title = nil
            botonFoto.configuration?.image = nil
        } else {
            botonFoto.configuration?.background.image = nil
            botonFoto.configuration?.title = "Toma foto o sube imagen"
            botonFoto.configuration?.image = UIImage(systemName: "camera.fill")
        }
    }


    // =================================================================
    //  MARK: - Utilidades
    // =================================================================

    private func ponerTitulo(_ texto: String, en boton: UIButton, color: UIColor) {
        if boton.configuration != nil {
            boton.configuration?.title = texto
            boton.configuration?.baseForegroundColor = color
        } else {
            boton.setTitle(texto, for: .normal)
            boton.setTitleColor(color, for: .normal)
        }
    }
}


// MARK: - Cámara

extension NuevoReporteViewController: UIImagePickerControllerDelegate,
                                      UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let imagen = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let imagen { mostrarFoto(imagen) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


// MARK: - Galería

extension NuevoReporteViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let proveedor = results.first?.itemProvider,
              proveedor.canLoadObject(ofClass: UIImage.self) else { return }

        proveedor.loadObject(ofClass: UIImage.self) { [weak self] objeto, error in
            guard let imagen = objeto as? UIImage else {
                if let error { print("No se pudo cargar la imagen:", error) }
                return
            }
            // La carga ocurre en segundo plano; la interfaz se toca en el hilo principal.
            DispatchQueue.main.async {
                self?.mostrarFoto(imagen)
            }
        }
    }
}


// =====================================================================
//  CÓMO CONECTARLO
//
//  1. Reemplaza el archivo anterior con este.
//
//  2. Conecta el outlet nuevo:
//     Ctrl+arrastra desde el View Controller (círculo amarillo) hasta
//     el botón "Toma foto o sube imagen" y elige  botonFoto.
//     (El outlet botonCategoria ya lo tienes conectado.)
//
//  3. Permiso de cámara: abre Info.plist, clic derecho, Add Row.
//     Key:   Privacy - Camera Usage Description
//     Value: SMSeguro usa la cámara para adjuntar evidencia del fraude.
//
//     La galería no necesita permiso porque PHPickerViewController
//     solo entrega la foto que el usuario elige.
//
//  4. Corre con Cmd+R. En el simulador solo verás "Elegir de la
//     galería"; la cámara aparece únicamente en un iPhone real.
// =====================================================================
